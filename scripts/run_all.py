#!/usr/bin/env python3
"""
run_all.py
Master automation script:
1. Runs Python ETL to build/refresh Knowledge Base
2. Runs SWI-Prolog logical correctness test suite
3. Runs SWI-Prolog computational profiler & benchmarks
4. Runs sample Decision Support System queries
"""

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
    swipl_exe = "swipl"

    # 1. Rebuild KB
    run_command([py_exe, str(root / "scripts" / "build_kb.py")], "Step 1: Running Python ETL Pipeline (Build KB)")

    # 2. Run Tests
    run_command([swipl_exe, "-s", str(root / "main.pl"), "-g", "run_tests, halt."], "Step 2: Running Prolog Test Suite (Logical Correctness)")

    # 3. Run Profiler
    run_command([swipl_exe, "-s", str(root / "main.pl"), "-g", "run_profiler, halt."], "Step 3: Running Prolog Profiler & Benchmarks (Efficiency)")

    # 4. Run Demo
    run_command([swipl_exe, "-s", str(root / "main.pl"), "-g", "demo, halt."], "Step 4: Executing DSS Recommendation Demos")

    print("\n=================================================================")
    print("[SUCCESS] All pipeline steps completed successfully!")
    print("=================================================================\n")

if __name__ == "__main__":
    main()
