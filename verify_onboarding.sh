#!/bin/bash

# Verification script for onboarding sample data wiring
# Run this to check if the changes are properly integrated

echo "🔍 Verifying Onboarding Sample Data Wiring..."
echo ""

# Check 1: Verify TODO comment is removed
echo "✓ Check 1: Verifying TODO comment removal..."
if grep -q "TODO.*Add tasks and boards to data stores" StickyToDo-SwiftUI/Views/Onboarding/OnboardingFlow.swift; then
    echo "  ❌ FAIL: TODO comment still exists"
    exit 1
else
    echo "  ✅ PASS: TODO comment removed"
fi

# Check 2: Verify sample data is wired in OnboardingFlow
echo "✓ Check 2: Verifying OnboardingFlow wiring..."
if grep -q "taskStore.add(task)" StickyToDo-SwiftUI/Views/Onboarding/OnboardingFlow.swift; then
    echo "  ✅ PASS: Tasks are added to TaskStore"
else
    echo "  ❌ FAIL: Tasks not wired to TaskStore"
    exit 1
fi

if grep -q "boardStore.add(board)" StickyToDo-SwiftUI/Views/Onboarding/OnboardingFlow.swift; then
    echo "  ✅ PASS: Boards are added to BoardStore"
else
    echo "  ❌ FAIL: Boards not wired to BoardStore"
    exit 1
fi

# Check 3: Verify DataManager uses comprehensive generator
echo "✓ Check 3: Verifying DataManager uses comprehensive generator..."
if grep -q "SampleDataGenerator.generateSampleData()" StickyToDo/Data/DataManager.swift; then
    echo "  ✅ PASS: DataManager uses comprehensive SampleDataGenerator"
else
    echo "  ❌ FAIL: DataManager not using comprehensive generator"
    exit 1
fi

# Check 4: Verify duplicate prevention
echo "✓ Check 4: Verifying duplicate prevention..."
if grep -q "hasCreatedSampleData" StickyToDo/Data/DataManager.swift; then
    echo "  ✅ PASS: Duplicate prevention implemented"
else
    echo "  ❌ FAIL: No duplicate prevention"
    exit 1
fi

# Check 5: Verify DataManager property in OnboardingCoordinator
echo "✓ Check 5: Verifying OnboardingCoordinator has DataManager..."
if grep -q "private var dataManager: DataManager?" StickyToDo-SwiftUI/Views/Onboarding/OnboardingFlow.swift; then
    echo "  ✅ PASS: OnboardingCoordinator has DataManager property"
else
    echo "  ❌ FAIL: DataManager property missing"
    exit 1
fi

# Check 6: Count sample tasks created
echo "✓ Check 6: Verifying sample data exists..."
TASK_COUNT=$(grep -c "tasks.append" StickyToDo/Utilities/SampleDataGenerator.swift || echo "0")
BOARD_COUNT=$(grep -c "boards.append" StickyToDo/Utilities/SampleDataGenerator.swift || echo "0")
echo "  ℹ️  Sample tasks generated: $TASK_COUNT"
echo "  ℹ️  Sample boards generated: $BOARD_COUNT"

if [ "$TASK_COUNT" -gt "10" ]; then
    echo "  ✅ PASS: Sufficient sample tasks (${TASK_COUNT})"
else
    echo "  ⚠️  WARNING: Low sample task count (${TASK_COUNT})"
fi

# Check 7: Verify file changes
echo "✓ Check 7: Verifying modified files exist..."
FILES=(
    "StickyToDo/Data/DataManager.swift"
    "StickyToDo-SwiftUI/Views/Onboarding/OnboardingFlow.swift"
    "StickyToDo/Utilities/SampleDataGenerator.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ Found: $file"
    else
        echo "  ❌ Missing: $file"
        exit 1
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ All verification checks PASSED!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Summary of Changes:"
echo "  • OnboardingFlow: Wired to TaskStore and BoardStore"
echo "  • DataManager: Uses comprehensive SampleDataGenerator"
echo "  • Duplicate Prevention: Implemented"
echo "  • Sample Data: ~$TASK_COUNT tasks, ~$BOARD_COUNT boards"
echo ""
echo "🧪 Next Steps:"
echo "  1. Build the project to verify compilation"
echo "  2. Run manual testing (see ONBOARDING_WIRING_REPORT.md)"
echo "  3. Test first-run experience end-to-end"
echo "  4. Verify sample data persists after restart"
echo ""
echo "📖 Full report: ONBOARDING_WIRING_REPORT.md"
echo ""
