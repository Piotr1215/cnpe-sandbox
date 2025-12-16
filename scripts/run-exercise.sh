#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXERCISES_DIR="${SCRIPT_DIR}/../exercises"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Verify we're using kind-cnpe context
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "none")
if [[ "$CURRENT_CONTEXT" != "kind-cnpe" ]]; then
    echo -e "${RED}Error: Wrong context '${CURRENT_CONTEXT}', expected 'kind-cnpe'${NC}"
    echo -e "Run: ${CYAN}just setup${NC} to create the cluster."
    exit 1
fi

# Domain descriptions for context
declare -A DOMAIN_DESC=(
    ["01-gitops-cd"]="GitOps and Continuous Delivery (25%)"
    ["02-platform-apis"]="Platform APIs and Self-Service (25%)"
    ["03-observability"]="Observability and Operations (20%)"
    ["04-architecture"]="Platform Architecture (15%)"
    ["05-security"]="Security and Policy Enforcement (15%)"
    ["00-test-setup"]="Test Setup (validation only)"
)

usage() {
    cat <<'USAGE_EOF'
Usage: run-exercise.sh <exercise-path> [options]

Examples:
  run-exercise.sh 01-gitops-cd/01-fix-broken-sync
  run-exercise.sh 01-gitops-cd/02-canary-deployment --timeout 300

Options:
  --setup-only   Create broken state only (practice mode, no cleanup)
  --check-only   Run assertions only (verify your fix)
  --timeout N    Override timeout in seconds (default: 420)
  --no-cleanup   Skip cleanup after exercise (for debugging)
  --verbose      Show full KUTTL output (for debugging)

Workflow:
  1. Setup creates broken state
  2. You fix the problem using kubectl/CLI
  3. KUTTL validates your fix
  4. Cleanup removes all exercise resources
USAGE_EOF
    exit 1
}

[[ $# -lt 1 ]] && usage

EXERCISE_PATH="$1"
SETUP_ONLY=false
CHECK_ONLY=false
NO_CLEANUP=false
VERBOSE=false
TIMEOUT=""

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --setup-only) SETUP_ONLY=true; shift ;;
        --check-only) CHECK_ONLY=true; shift ;;
        --no-cleanup) NO_CLEANUP=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        *) usage ;;
    esac
done

# Parse domain and exercise
DOMAIN="${EXERCISE_PATH%%/*}"
EXERCISE="${EXERCISE_PATH#*/}"
DOMAIN_DIR="${EXERCISES_DIR}/${DOMAIN}"
EXERCISE_DIR="${DOMAIN_DIR}/${EXERCISE}"

if [[ ! -d "$EXERCISE_DIR" ]]; then
    echo -e "${RED}Exercise not found: ${EXERCISE_DIR}${NC}"
    echo ""
    echo "Available exercises:"
    find "$EXERCISES_DIR" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | \
        sed "s|${EXERCISES_DIR}/||" | sort
    exit 1
fi

# Extract namespace from setup file for cleanup
EXERCISE_NS=""
SETUP_FILE="${EXERCISE_DIR}/setup.yaml"
if [[ -f "$SETUP_FILE" ]]; then
    EXERCISE_NS=$(grep -E "^  name: cnpe-" "$SETUP_FILE" 2>/dev/null | head -1 | awk '{print $2}' || true)
    if [[ -z "$EXERCISE_NS" ]]; then
        EXERCISE_NS=$(grep -E "namespace: cnpe-" "$SETUP_FILE" 2>/dev/null | head -1 | awk '{print $2}' || true)
    fi
fi

# Cleanup function
cleanup_exercise() {
    if [[ "$NO_CLEANUP" == "true" ]]; then
        echo -e "${YELLOW}Skipping cleanup (--no-cleanup)${NC}"
        return
    fi

    if [[ -n "$EXERCISE_NS" ]]; then
        echo -e "${YELLOW}Cleaning up namespace: ${EXERCISE_NS}...${NC}"
        kubectl delete namespace "$EXERCISE_NS" --wait=false 2>/dev/null || true
    fi

    if [[ -f "$SETUP_FILE" ]]; then
        kubectl delete -f "$SETUP_FILE" 2>/dev/null || true
    fi
}

# Master cleanup
cleanup_all() {
    local exit_code=$?

    [[ -n "${TIMER_PID:-}" ]] && kill $TIMER_PID 2>/dev/null || true

    printf "\r%80s\r" " "

    rm -f "${KUTTL_STATUS:-}" 2>/dev/null || true

    if [[ "${CLEANUP_ON_EXIT:-false}" == "true" ]]; then
        echo ""
        cleanup_exercise
    fi

    exit $exit_code
}

# Get timeout
if [[ -z "$TIMEOUT" ]]; then
    TIMEOUT=$(grep -E "^timeout:" "${DOMAIN_DIR}/kuttl-test.yaml" 2>/dev/null | awk '{print $2}')
    TIMEOUT=${TIMEOUT:-420}
fi

# Display header
clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
printf "${BLUE}║${NC} ${BOLD}%-61s${NC} ${BLUE}║${NC}\n" "CNPE Exercise: ${EXERCISE_PATH}"
printf "${BLUE}║${NC} ${CYAN}%-61s${NC} ${BLUE}║${NC}\n" "Category: ${DOMAIN_DESC[$DOMAIN]:-Unknown}"
printf "${BLUE}║${NC} ${CYAN}%-61s${NC} ${BLUE}║${NC}\n" "Time Limit: $((TIMEOUT / 60)) minutes"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ -f "${EXERCISE_DIR}/README.md" ]]; then
    cat "${EXERCISE_DIR}/README.md"
    echo ""
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Setup-only mode
if [[ "$SETUP_ONLY" == "true" ]]; then
    echo -e "${YELLOW}Setup mode: Creating broken state...${NC}"
    if kubectl apply -f "$SETUP_FILE" 2>&1; then
        echo ""
        echo -e "${GREEN}Setup complete.${NC}"
        echo -e "Namespace: ${CYAN}${EXERCISE_NS}${NC}"
        echo ""
        echo "When done practicing, cleanup with:"
        echo -e "  ${CYAN}kubectl delete namespace ${EXERCISE_NS}${NC}"
        echo ""
        echo "Or verify your fix with:"
        echo -e "  ${CYAN}$0 ${EXERCISE_PATH} --check-only${NC}"
    else
        echo -e "${RED}Setup failed!${NC}"
        exit 1
    fi
    exit 0
fi

# Check-only mode
if [[ "$CHECK_ONLY" == "true" ]]; then
    echo -e "${YELLOW}Verifying your solution...${NC}"
    echo ""

    KUTTL_CMD="kubectl-kuttl test ${DOMAIN_DIR} --config ${DOMAIN_DIR}/kuttl-test.yaml --test ${EXERCISE} --timeout ${TIMEOUT}"

    if $KUTTL_CMD; then
        echo ""
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  ✓ PASSED                                                     ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    else
        echo ""
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ✗ FAILED - Review the diff above                             ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
        exit 1
    fi
    exit 0
fi

# Full run mode
echo ""
echo -e "${BOLD}Workflow:${NC}"
echo "  1. Press Enter -> Setup creates broken state"
echo "  2. Fix the problem using kubectl, CLI tools, or UIs"
echo "  3. KUTTL continuously checks until pass or timeout"
echo "  4. Cleanup runs automatically (pass, fail, or Ctrl+C)"
echo ""
echo -e "${YELLOW}Press Enter to start timer...${NC}"
read -r

CLEANUP_ON_EXIT=true
trap cleanup_all EXIT INT TERM

echo -e "${YELLOW}Creating broken state...${NC}"

# Apply setup - retry once if CRDs need time to establish
if ! kubectl apply -f "$SETUP_FILE" 2>&1; then
    echo -e "${YELLOW}Waiting for CRDs to establish...${NC}"
    
    # Wait for any CRDs in the setup file to be established
    crds=$(grep -E "^kind: CustomResourceDefinition" -A5 "$SETUP_FILE" 2>/dev/null | grep "name:" | awk '{print $2}' || true)
    for crd in $crds; do
        kubectl wait --for=condition=Established "crd/${crd}" --timeout=30s 2>/dev/null || true
    done
    
    sleep 2
    
    # Retry apply
    if ! kubectl apply -f "$SETUP_FILE" 2>&1; then
        echo -e "${RED}Setup failed!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Setup complete. Fix the problem now!${NC}"
echo ""

# Load step descriptions
declare -A STEP_DESC
if [[ -f "${EXERCISE_DIR}/steps.txt" ]]; then
    while IFS=: read -r num desc; do
        STEP_DESC[$num]="$desc"
    done < "${EXERCISE_DIR}/steps.txt"
fi

# Count total steps
TOTAL_STEPS=$(find "$EXERCISE_DIR" -maxdepth 1 -name "*-assert.yaml" 2>/dev/null | wc -l | tr -d ' ')
CURRENT_STEP=0

KUTTL_STATUS=$(mktemp)
KUTTL_CMD="kubectl-kuttl test ${DOMAIN_DIR} --config ${DOMAIN_DIR}/kuttl-test.yaml --test ${EXERCISE} --timeout ${TIMEOUT}"

echo -e "${CYAN}Checking assertions...${NC}"
echo ""

START_TIME=$(date +%s)

# Timer function
show_timer() {
    local start=$1
    local timeout=$2
    local step_info="$3"
    while true; do
        local elapsed=$(($(date +%s) - start))
        local remaining=$((timeout - elapsed))
        [[ $remaining -lt 0 ]] && remaining=0

        local color="$GREEN"
        [[ $remaining -lt 120 ]] && color="$YELLOW"
        [[ $remaining -lt 60 ]] && color="$RED"

        local timer_text
        timer_text=$(printf "%02d:%02d" $((remaining / 60)) $((remaining % 60)))
        printf "\r${YELLOW}⏳ %s${NC} ${color}[${timer_text}]${NC}  " "$step_info"
        sleep 1
    done
}

# Start timer
show_timer "$START_TIME" "$TIMEOUT" "Step 1/${TOTAL_STEPS}: Waiting for fix..." &
TIMER_PID=$!

# Process KUTTL output
$KUTTL_CMD 2>&1 | while IFS= read -r line; do
    # Verbose mode
    if [[ "$VERBOSE" == "true" ]]; then
        printf "\r%80s\r"
        echo "$line"
        continue
    fi

    # Skip noise
    if [[ "$line" =~ "running command:" ]] || [[ "$line" =~ ^[[:space:]]*\]$ ]]; then
        continue
    fi
    
    # Step completed
    if [[ "$line" =~ "test step completed" ]]; then
        step_num=$(echo "$line" | sed -n 's/.*test step completed \([0-9]*\).*/\1/p')
        
        # Kill old timer, clear line
        kill "$TIMER_PID" 2>/dev/null || true
        printf "\r%80s\r"
        
        step_desc="${STEP_DESC[$step_num]:-}"
        if [[ -n "$step_desc" ]]; then
            echo -e "${GREEN}✓ Step $((step_num + 1))/${TOTAL_STEPS}:${step_desc}${NC}"
        else
            echo -e "${GREEN}✓ Step $((step_num + 1))/${TOTAL_STEPS} passed${NC}"
        fi
        
        # Parse assert file
        assert_file=""
        for f in "${EXERCISE_DIR}/0${step_num}-assert.yaml" "${EXERCISE_DIR}/${step_num}-assert.yaml"; do
            if [[ -f "$f" ]]; then
                assert_file="$f"
                break
            fi
        done
        if [[ -n "$assert_file" ]]; then
            "${SCRIPT_DIR}/parse-assert.sh" "$assert_file"
        fi
        
        CURRENT_STEP=$((step_num + 1))
        
        # Start new timer for next step
        if [[ $CURRENT_STEP -lt $TOTAL_STEPS ]]; then
            show_timer "$START_TIME" "$TIMEOUT" "Step $((CURRENT_STEP + 1))/${TOTAL_STEPS}: Waiting for fix..." &
            TIMER_PID=$!
        fi
        continue
    fi
    
    # Step failed
    if [[ "$line" =~ "test step failed" ]]; then
        kill "$TIMER_PID" 2>/dev/null || true
        printf "\r%80s\r"
        echo -e "${RED}✗ Step $((CURRENT_STEP + 1))/${TOTAL_STEPS} timed out${NC}"
        continue
    fi
    
    # Final results
    if [[ "$line" =~ ^---\ (PASS|FAIL) ]]; then
        kill "$TIMER_PID" 2>/dev/null || true
        printf "\r%80s\r"
        echo "$line"
        continue
    fi
done
PIPE_STATUS=${PIPESTATUS[0]}

# Cleanup timer
kill "$TIMER_PID" 2>/dev/null || true
TIMER_PID=""
printf "\r%80s\r" " "

if [[ $PIPE_STATUS -eq 0 ]]; then
    echo 0 > "$KUTTL_STATUS"
else
    echo 1 > "$KUTTL_STATUS"
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

KUTTL_EXIT=$(cat "$KUTTL_STATUS" 2>/dev/null || echo "1")

echo ""
if [[ "$KUTTL_EXIT" == "0" ]]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    printf "${GREEN}║  ✓ PASSED in %d:%02d                                            ║${NC}\n" $((ELAPSED / 60)) $((ELAPSED % 60))
    if [[ $ELAPSED -le 420 ]]; then
        echo -e "${GREEN}║  Within 7-minute exam target!                                 ║${NC}"
    else
        echo -e "${YELLOW}║  Over 7-minute target - practice more!                        ║${NC}"
    fi
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    printf "${RED}║  ✗ FAILED after %d:%02d                                         ║${NC}\n" $((ELAPSED / 60)) $((ELAPSED % 60))
    echo -e "${RED}║  Review the errors above                                      ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
