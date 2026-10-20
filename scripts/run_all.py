#!/usr/bin/env python3
"""
run_all.py
Master automation script:
1. Runs Python ETL to build/refresh Knowledge Base
2. Runs SWI-Prolog or Python logical correctness test suite
3. Runs Computational Profiler & Benchmarks (if swipl is present)
4. Runs Context-Aware DSS Recommendation Demos

Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
"""

import shutil
import subprocess
import sys
from pathlib import Path

def run_command(cmd, desc):
    print(f"\n=================================================================")
    print(f"[*] {desc}")
    print(f"    Command: {' '.join(cmd)}")
    print(f"=================================================================")
    res = subprocess.run(cmd)
    if res.returncode != 0:
        print(f"[!] Step failed with exit code {res.returncode}")
        sys.exit(res.returncode)
    print(f"[+] {desc} completed successfully.")

def main():
    root = Path(__file__).resolve().parent.parent
    py_exe = sys.executable
    swipl_exe = shutil.which("swipl")

    # 1. Rebuild KB
    run_command([py_exe, str(root / "scripts" / "build_kb.py")], "Step 1: Running Python ETL Pipeline (Build KB)")

    # 2. Run Tests
    if swipl_exe:
        run_command([swipl_exe, "-s", str(root / "main.pl"), "-g", "run_tests, halt."], "Step 2: Running Prolog Test Suite (Logical Correctness)")
    else:
        print("\n[*] SWI-Prolog ('swipl') not detected on PATH; executing Python test verification suite...")
        run_command([py_exe, str(root / "tests" / "test_verification.py")], "Step 2: Running Test Verification Suite (Logical Correctness)")

    # 3. Run Profiler
    if swipl_exe:
        run_command([swipl_exe, "-s", str(root / "main.pl"), "-g", "run_profiler, halt."], "Step 3: Running Prolog Profiler & Benchmarks (Efficiency)")
    else:
        print("\n[*] (SWI-Prolog not in PATH: Native profiler available via 'swipl -s main.pl -g run_profiler')")

    # 4. Run Demo
    if swipl_exe:
        run_command([swipl_exe, "-s", str(root / "main.pl"), "-g", "demo, halt."], "Step 4: Executing Prolog DSS Recommendation Demos")
    else:
        run_command([py_exe, str(root / "scripts" / "demo.py")], "Step 4: Executing DSS Recommendation Demos")

    print("\n=================================================================")
    print("[SUCCESS] All pipeline steps completed successfully!")
    print("=================================================================\n")

if __name__ == "__main__":
    main()
