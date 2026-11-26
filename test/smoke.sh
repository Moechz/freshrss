#!/bin/bash
# ===========================================================================
# FreshRSS functional smoke test (called by ../../smoke.py with the base URL
# of the isolated staging container).
#
# FreshRSS is stateful (SQLite + accounts), so "the port answers" is not enough.
# This script drives the real first-run flow over HTTP, exactly like a user:
#
#   1. the app answers and redirects to the installer or the login page
#   2. the installer can create config.php, the SQLite database and the
#      administrator account (step 0 -> step 4). This is where 1.30.4-3 broke:
#      without data/users, data/tokens, data/favicons (cli/prepare.php was not
#      run by the wrapper) the first-run page threw touch() warnings and the
#      account/database creation did not complete, so the app was unusable.
#   3. the login form accepts the account just created
#   4. the API route exists (FreshRSS ships the API disabled by default, so an
#      authentication failure/503 is fine, a 404/500 is not)
#
# Usage: bash test/smoke.sh http://127.0.0.1:<port>
# Exit code: 0 = usable, non-zero = broken.
# ===========================================================================
set -u

BASE="${1:-}"
[ -n "$BASE" ] || { echo "usage: $0 <base-url>"; exit 2; }
BASE="${BASE%/}"
USER_NAME="${SMOKE_USER:-smokeadmin}"
USER_PASS="${SMOKE_PASS:-Smoke-Pass-2026}"
JAR="$(mktemp)"; trap 'rm -f "$JAR"' EXIT
UA="Mozilla/5.0 (compatible; tos-freshrss-smoke)"
FAILED=0

ok()   { echo "  ok   : $*"; }
bad()  { echo "  FAIL : $*"; FAILED=$((FAILED + 1)); }

# curl helpers (cookie jar shared so the installer/login session sticks)
get()  { curl -sS -m 25 -A "$UA" -b "$JAR" -c "$JAR" "$@"; }
code() { curl -sS -m 25 -o /dev/null -w '%{http_code}' -A "$UA" -b "$JAR" -c "$JAR" "$@"; }
body() { curl -sS -m 25 -A "$UA" -b "$JAR" -c "$JAR" "$@" 2>/dev/null; }

# ---------------------------------------------------------------- 1) reachable
c="$(code "$BASE/")"
case "$c" in
  200|301|302|303|307|308) ok "GET / -> $c" ;;
  *) bad "GET / -> ${c:-no response} (the app does not answer)"; exit 1 ;;
esac

# The first-run page is at /i/ (FreshRSS redirects / -> /i/). Follow it once to
# make sure the landing page is a real page, not a redirect loop or empty shell.
landing="$(body -L "$BASE/")"
lc="$(code -L "$BASE/")"
case "$lc" in 200) ;; *) bad "GET / (following redirects) -> $lc" ;; esac
case "$landing" in *FreshRSS*) ;; *) bad "landing page does not mention FreshRSS" ;; esac
case "$landing" in *"Fatal error"*|*"Parse error"*|*"No such file or directory"*)
  bad "landing page contains a PHP error" ;; esac

# ------------------------------------------------------------ 2) installation
if printf '%s' "$landing" | grep -q 'Installation'; then
  echo "  info : first run, driving the installer over HTTP"
  # step 0: language
  c="$(code -d 'language=en' "$BASE/i/?step=0")"
  case "$c" in 200|302|303) ok "installer step 0 (language) -> $c" ;;
               *) bad "installer step 0 -> $c" ;; esac

  # step 1: requirements. The page must show the environment checks.
  s1="$(body "$BASE/i/?step=1")"
  case "$s1" in *"FreshRSS"*) ok "installer step 1 (requirements) renders" ;;
                *) bad "installer step 1 does not render" ;; esac

  # step 2: SQLite, creates data/config.php and the database schema.
  c="$(code -d 'type=sqlite' "$BASE/i/?step=2")"
  case "$c" in 200|302|303) ok "installer step 2 (SQLite database) -> $c" ;;
               *) bad "installer step 2 (SQLite database) -> $c (database/config could not be created)" ;; esac

  # step 3: administrator account. This is the step that needs data/users,
  # data/tokens and data/cache to exist (created by cli/prepare.php).
  s3="$(body "$BASE/i/?step=3")"
  case "$s3" in *default_user*) ok "installer step 3 form (administrator) renders" ;;
                *) bad "installer step 3 form does not render (data dirs missing?)" ;; esac
  c="$(code -d "default_user=$USER_NAME&auth_type=form&passwordPlain=$USER_PASS" "$BASE/i/?step=3")"
  case "$c" in 200|302|303) ok "installer step 3 (create administrator) -> $c" ;;
               *) bad "installer step 3 (create administrator) -> $c" ;; esac

  # step 4 is the success page and is only rendered after the administrator was
  # created and committed (alert-success is part of printStep4()).
  s4="$(body "$BASE/i/?step=4")"
  case "$s4" in *alert-success*) ok "installer step 4 (success page) renders" ;;
                *) bad "installer step 4 shows no success page (installation did not complete)" ;; esac

  # step 5 finishes the setup (applied migrations) and redirects to the app.
  c="$(code "$BASE/i/?step=5")"
  case "$c" in 200|302|303) ok "installer step 5 (finish) -> $c" ;;
               *) bad "installer step 5 (finish) -> $c" ;; esac
else
  echo "  info : already installed, skipping the installer"
fi

# ---------------------------------------------------------------- 3) login page
# /i/ redirects to the login form for an anonymous visitor, so follow it.
login="$(body -L "$BASE/i/")"
case "$login" in *passwordPlain*|*formLogin*|*"Log in"*|*"login"*) ok "login page renders" ;;
                 *) bad "login page does not look like a FreshRSS login form" ;; esac

# If we created the account above, log in with it: that proves the database,
# the user files and the password storage all work.
#
# FreshRSS deletes the session cookie on the first render of the login form
# (Minz_Session::deleteLegacyCookie, a cookie from before 1.29), so the very
# first POST answers "invalid session" and the second attempt succeeds - a
# browser does the same two steps. Retry a few times instead of pretending the
# first POST must work.
if printf '%s' "$landing" | grep -q 'Installation'; then
  authenticated=""
  for attempt in 1 2 3; do
    page="$(body -L "$BASE/i/")"
    csrf="$(printf '%s' "$page" | grep -o 'name="_csrf" value="[^"]*"' | head -1 | sed 's/.*value="//; s/"$//')"
    [ -n "$csrf" ] || { bad "login page has no CSRF token"; break; }
    c="$(code -d "_csrf=$csrf&username=$USER_NAME&passwordPlain=$USER_PASS" \
             "$BASE/i/?c=auth&a=login")"
    after="$(body -L "$BASE/i/")"
    if printf '%s' "$after" | grep -q 'id="stream"'; then
      authenticated="yes"
      ok "login (attempt $attempt) -> $c, authenticated stream page rendered"
      break
    fi
    [ "$attempt" = 1 ] && echo "  info : login attempt 1 rejected (legacy cookie cleanup), retrying"
    [ "$attempt" = 3 ] && bad "login failed after 3 attempts (last HTTP $c)"
  done
fi

# ------------------------------------------------------------------ 4) API route
# FreshRSS ships the API disabled (admin setting "api_enabled"), so 200 with
# "Service Unavailable" or 401/403 is fine here. 404/500 means the route is gone.
ac="$(code "$BASE/api/greader.php")"
case "$ac" in
  200|401|403) ok "API route /api/greader.php -> $ac" ;;
  404|000|"") bad "API route /api/greader.php -> ${ac:-no response} (route missing)" ;;
  *) bad "API route /api/greader.php -> $ac (unexpected)" ;;
esac

# The public favicon endpoint must exist as well (favicons are cached in
# data/favicons, which only exists when cli/prepare.php ran).
fc="$(code "$BASE/f.php?h=0")"
case "$fc" in
  200|204|404|400) ok "favicon endpoint /f.php -> $fc" ;;
  000|"") bad "favicon endpoint /f.php -> no response" ;;
  *) bad "favicon endpoint /f.php -> $fc" ;;
esac

echo
if [ "$FAILED" -ne 0 ]; then
  echo "  smoke FAILED ($FAILED checks)"
  exit 1
fi
echo "  smoke OK (install -> login -> API route)"
exit 0
