#!/bin/bash
# ---------------------------------------------------------------------------
# 《战争的雷霆》构建脚本
#
# 用法：  ./build.sh
# 产物：  main.pdf                                    （工作副本，不入库）
#         战争的雷霆——记一种可能的中国历史.pdf        （分发副本，入库）
#         构建日志 build.log（不入库）
#
# 依赖：  xelatex（TeX Live 2022+）
#         ctex / xeCJK / zhnumber（用户态安装，见 scripts/setup-tex.sh）
#         字体：Noto Serif、Noto Sans、Noto Serif CJK SC、Noto Sans CJK SC
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(cd ../.. && pwd)"

JOB=main
DIST="战争的雷霆——记一种可能的中国历史.pdf"
PASSES=3   # 3 遍是下限：目录/交叉引用 1 遍、remember picture 定位 1 遍、稳定 1 遍

# ---- 前置检查 -------------------------------------------------------------
command -v xelatex >/dev/null 2>&1 || {
  echo "错误：未找到 xelatex，请先安装 TeX Live。" >&2; exit 1; }

# 中文宏包：优先后用系统 TeX Live；系统缺包时回退到仓库内的 texmf/
if ! kpsewhich ctex.sty >/dev/null 2>&1; then
  if [ -d "$ROOT/texmf" ]; then
    export TEXMFHOME="$ROOT/texmf"
    echo "提示：系统未提供 ctex，改用 ./texmf。"
  else
    echo "错误：系统未安装 ctex / xeCJK / zhnumber。" >&2
    echo "      请用系统包管理器安装 TeX Live 中文支持，或运行 ../../scripts/setup-tex.sh" >&2
    echo "      把它们装进 ./texmf。" >&2
    exit 1
  fi
fi

# ---- 逐遍编译 -------------------------------------------------------------
for i in $(seq 1 "$PASSES"); do
  if ! xelatex -interaction=nonstopmode -halt-on-error "$JOB.tex" > build.log 2>&1; then
    echo "编译失败（第 $i 遍）。错误摘要：" >&2
    grep -E "^!" -A6 build.log | head -40 >&2
    exit 1
  fi
done

# ---- 质量提示 -------------------------------------------------------------
BAD=$(grep -c "Overfull" build.log || true)
UNRES=$(grep -c "undefined references" build.log || true)
MISS=$(grep -c "Missing character" build.log || true)

printf '%-12s %s\n' "页数"       "$(pdfinfo $JOB.pdf | awk '/^Pages/{print $2}')"
printf '%-12s %s\n' "Overfull"   "$BAD"
printf '%-12s %s\n' "未解析引用" "$UNRES（第 3 遍后应为 0）"
printf '%-12s %s\n' "缺字"       "$MISS（应为 0）"

if [ "$MISS" -gt 0 ]; then
  echo "警告：存在缺字，见 build.log 中的 'Missing character'。" >&2
fi

cp -f "$JOB.pdf" "$DIST"
echo "构建完成：$DIST"
