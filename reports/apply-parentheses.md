# 函数应用括号规范与调用点修复

## 范围与基线

- 独立工作树：`/home/sky/workspace/gray/Fulcrum-Notes-SNL-apply-parentheses`
- 任务分支：`notes/apply-parentheses`，从 fetch 后的 `origin/main`（`3d08fc84b8b6ef8d7d0103237904699372e3113d`）建立。没有切换或编辑其他工作树；不 push、不合并 main。
- 只读 Toolkit：`/home/sky/workspace/cat/SNL-Agent-Toolkit`，版本 `b9270cde80821476006a9623426fb9acb873d0f0`。已读 AGENT、最新 SNL Ecosystem/DSL、CLI 手册与目标 CONVENTIONS；执行随仓 `dist/cli/snl.mjs`，以 `--help` 的实际实现为准。未改 Toolkit 或 cat 阅读器。
- 原始证据目录：`/tmp/snl-apply-parentheses-evidence/`（下文证据均相对此目录）。输入 payload 仅在该临时目录，不入库。

## 结果

CONVENTIONS 新增 §12.5.1：默认 `paren`（`#0(#1)`）不动，`none`（`#0#1`）仅显式备选；参数已有完整括号且形成冗余外壳时才改调用点。保留元组/序列与嵌套、优先级边界，不扁平化 `f((a,b),c)`，不改变一般 `f(x)` 或 `f(g(x))`。明确 `VecNotation` 是 `Fin n → T` 的有限序列，不是 Prod。

通过 canonical `entry get → entry update --if-match → entry get/latex` 修复 **8 个 Entry、17 个 Type.apply 节点**。没有直接改 CAS。所有实参树、绑定坐标、其他字段及元数据均保持；只为指定应用节点写 `[none]`。没有宏变动，也没有 Library/计数器/关系图变动。

| Entry ID | 修复节点数 | 读回结果要点 |
|---|---:|---|
| `Bornology.IsBounded` | 1 | `d(x,y)`；量化用 `(x,y)` 保留 |
| `ContinuousMap.Homotopy` | 2 | `H(0,x)`、`H(1,x)`；`f0(x)`、`f1(x)` 不动 |
| `DG.def.partialDeriv` | 4 | `∂₁X(u,v)`、`∂₂X(u,v)`、`X(t,v)`、`X(u,t)`；外层结果二元组和 lambda 求导边界保留 |
| `DG.def.regularParametrizedSurface` | 2 | 两个偏导的参数括号只保留一层 |
| `DG.def.rotation90` | 1 | `J(x,y)`；结果 `VecNotation[default](-y,x)` 不动 |
| `Path.Homotopic.hcomp` | 2 | `H(z.1,2z.2)`、`K(z.1,2z.2−1)`；分段边界和乘积参数保留 |
| `Path.Homotopy` | 4 | `H(0,s)`、`H(1,s)`、`H(u,0)`、`H(u,1)`；`p0(s)`、`p1(s)` 不动 |
| `Topology.def.openBall` | 1 | `d(x,y)`；集合构造括号保留 |

## 宏内容 diff

以下均为上下文，**宏内容与默认顺序没有变化**：

```diff
 # TypeTheory
 Type.apply [paren] => $ #0(#1) $  （首位/隐式默认，保持）
 Type.apply [none] => $ #0#1 $  （备选，保持）
 Prod.pair [pair] => $ \left(#0, #1\right) $  （隐式默认，保持）
 # SetTheory
 Prod.mk [default] => $ \left(#2, #3\right) $  （保持）
 Prod.mk [authored] => $ \left(#2, #3\right) $  （保持）
 # BasicOperators
 VecNotation [default] => $ \left(#*\right) $  （保持；separator 为逗号空格）
 VecNotation [bare] => $ #* $  （保持；separator 为逗号空格）
```

## Entry 树 diff

以下为原 Library 层级的局部切片；`−/+` 表示该节点正文变化，不是删除重建或移位。树、ID、kind、标题均不变。

```diff
 algebraic-topology
 └── AlgebraicTopology.sec.algebraicTopology
     └── AlgebraicTopology.subsec.homotopies
-        ├── ContinuousMap.Homotopy  [2 个 apply[paren]]
+        ├── ContinuousMap.Homotopy  [2 个 apply[none]]
-        ├── Path.Homotopy  [4 个 apply[paren]]
+        ├── Path.Homotopy  [4 个 apply[none]]
         └── Path.Homotopic
-            └── Path.Homotopic.hcomp  [2 个 apply[paren]]
+            └── Path.Homotopic.hcomp  [2 个 apply[none]]
 differential-geometry
 └── DG.sec.curveAndSurfaceLocalTheory
     ├── DG.subsec.planeCurveTheory
-    │   └── DG.def.rotation90  [1 个隐式 apply[paren]]
+    │   └── DG.def.rotation90  [1 个显式 apply[none]]
     └── DG.subsec.surfaces
-        ├── DG.def.partialDeriv  [4 个隐式 apply[paren]]
+        ├── DG.def.partialDeriv  [4 个显式 apply[none]]
-        └── DG.def.regularParametrizedSurface  [2 个隐式 apply[paren]]
+        └── DG.def.regularParametrizedSurface  [2 个显式 apply[none]]
 point-set-topology
 └── Topology.sec.pointSet
     └── Topology.sec.metric
         └── Topology.subsec.basicConceptsMetric
-            ├── Bornology.IsBounded  [1 个隐式 apply[paren]]
+            ├── Bornology.IsBounded  [1 个显式 apply[none]]
-            └── Topology.def.openBall  [1 个隐式 apply[paren]]
+            └── Topology.def.openBall  [1 个显式 apply[none]]
```

## 全库审计覆盖

- CLI 分页穷尽：878 Entries、851 Macros、16 Libraries；保存 `entry-baseline.json`、`macro-baseline.json`、`library-baseline.json`。
- 实际 SNL-Basics parser 解析全部 **596 个非空 SNL 正文，0 解析错误**。
- 逐 AST 遍历发现 **95 Entries 中 249 个 Type.apply**，并检查 **41 个 tuple/sequence/VecNotation/Prod.mk/Prod.pair/Type.pair 相关节点**。参数模板来自完整宏清单，不按显示字符猜结构；清单含路径、样式和完整实参子树，见 `ast-audit.json`。
- 17 个重复外壳全部修复；`Type.def.Currying` 已用 `apply[none](f,Prod.mk[authored](,,x,y))`，原样保留。普通应用、嵌套函数应用、负数及算术表达式的应用外括号全部保留。
- 此 **origin/main 基线没有任何 `VecNotation[bare]` 调用**，因此没有伪造一次该迁移；规范明确其许可的等义改写形式。已有 VecNotation 默认括号与序列类别原样保留。
- 上述两类相关 Entry 的并集 **103 个**全部执行 canonical `entry latex` 成功，见 `all-related-latex.json`。这不意味着库里既有数学表述或所有 block export 占位符均已修复；本任务只审函数应用括号，不改无关历史问题。

## 验证与证据

1. `validate-before.json`、`validate-after.json`、`validate-staged.json`：基线、修改后和 `git checkout-index` 重建暂存树均 `ok: true`、`valid: true`、`issues: []`。Entries 878、Macros 851、Relationships 2844、Libraries 16 均不变。
2. 每个受影响 ID 有 `*.readback.json`、`*.latex-before.json`、`*.latex-after.json`。已逐一阅读八个修改后的 LaTeX；`changes.json` 保存 revision-aware 写入回执及前后完整实体。
3. `verify.mjs` 对修改前后 AST 深比较：恰好 17 个指定路径从 paren/隐式 paren 变成 none，其余 AST 完全相同；除 SNL 字符串外实体字段完全相同。运行结果保存为 `verification.json`。`git diff --check` 和 `git diff --cached --check` 均通过。
4. 使用临时只读阅读器 `127.0.0.1:4937`，root 为本任务 worktree，实际打开并展开 `point-set-topology`、`algebraic-topology`、`differential-geometry`。八个 Entry 均存在并有非空数学输出；逐条检查真实 DOM 中 Type.apply 的样式与文本，**17 个 none 调用均显示单层参数括号，0 个受影响 Entry KaTeX error**。普通 `f0(x)`、`p0(s)` 等仍为 paren；lambda 求导的必要括号保留。`browser-results.json`、三个 `*.html.json`、三个 `*.errors.json` 为实测记录。
5. 八个 `<Entry ID>.png` 是实际 Chromium 阅读器截图，供父 agent 目视复核。**本轮截图像素目视核验未完成**：`browser_vision` 的辅助视觉返回“截图无法显示/读取”，其随附示例公式不属于证据，已弃用；不能把成功截图/DOM 检查冒称目视通过。阅读器已实际渲染，DOM 数学内容已逐条检查。
6. 临时脚本 `audit.mjs`、`apply.py`、`verify.mjs`、`final-audit.py`、`browser-check.py` 均保留在证据目录；它们不是仓库产品代码。`apply.py` 仅主入口执行写入，不应再次运行。浏览器自动化先等待页面按钮出现再展开，避免首次载入时元素未就绪。

## 边界与交付

- 已完成授权内容编辑和真实 CLI/阅读器 DOM 验证；像素目视检查明确留给父 agent。
- 临时 Playwright 安装路径遇到 `uv` 不存在、pip 超时，改用本机已有 agent-browser 的**独立 session**完成八项浏览器检查，没有依赖安装结果或伪造截图分析。
- 提交仅含 `CONVENTIONS.md`、八个 canonical Entry 文件及本报告；提交后停止写入，由父 agent 复核。证据不入 Git，需保留上述 `/tmp` 目录以便审阅。
