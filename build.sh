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

JOB=main
DIST="战争的雷霆——记一种可能的中国历史.pdf"
PASSES=3   # 3 遍是下限：目录/交叉引用 1 遍、remember picture 定位 1 遍、稳定 1 遍

# ---- 前置检查 -------------------------------------------------------------
command -v xelatex >/dev/null 2>&1 || {
  echo "错误：未找到 xelatex，请先安装 TeX Live。" >&2; exit 1; }

if [ ! -d texmf ]; then
  echo "错误：缺少本地 TeX 依赖目录 ./texmf。" >&2
  echo "      请先运行 scripts/setup-tex.sh 安装 ctex / xeCJK / zhnumber。" >&2
  echo "      （本机为 Arch 的 partial TeX Live，缺中文宏包，需用户态安装。）" >&2
  exit 1
fi

export TEXMFHOME="$PWD/texmf"

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
