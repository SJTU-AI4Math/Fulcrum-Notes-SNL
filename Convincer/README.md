# Convincer：可追溯的条件论证

这是最小可运行原型，不是新的逻辑公理，也不把“说服了我”冒充“Lean 证明了”。

- `p : Prop` 是被讨论的命题。
- `Convincing p : Type 1` 是论证数据，不受 `Prop` 的证明无关性抹除。
- 刚性步骤必须给出真正的 Lean 证明；非形式化步骤显式记录 Evidence。
- `#evidence argument` 递归展开依赖结构，不必相信或执行任何 Evidence。

## 运行

只需仓库钉住的 Lean 4.28.0（通过 elan）和 Python，不需要下载 Mathlib：

```sh
python3 Convincer/check.py
```

Windows 使用 `python Convincer/check.py`。脚本逐个编译模块，检查公开 import、
原实验入口、结构断言、溯源输出、公理依赖和必须失败的反例；最多启动一个 Lean。
产物写入 `.lake/convincer/`，不会覆盖 Mathlib 或其他库的构建缓存。

已安装整个仓库的 Lake 依赖时，也可运行有限目标 `lake build Convincer`。
本次验证走的是上述隔离检查，不声称验证了整个仓库的 Lake/Mathlib 构建。

## 最小用法

```lean
import Convincer

convince observed : 1 = 2 := by
  evidence {
    id := "observation-1"
    explanation := "作者的非形式化观察；这个例子故意选择假命题"
    source := "notes:experiment-1"
  }

convince conclusion : 2 = 1 := by
  have h ← observed
  exact h.symm

#evidence conclusion
#print axioms conclusion
```

`h` 只在局部的**条件证明**中使用。生成的对象包含：

1. `observed` 的完整论证数据；
2. Lean 检查的刚性规则 `(1 = 2) → (2 = 1)`；
3. 组合两者的显式节点。

它没有生成 `2 = 1` 的全局证明，不能拿 `conclusion` 去证明普通 Lean 定理。
`#print axioms conclusion` 无公理只说明“这个论证数据的构造无公理”，并不说明
`2 = 1` 成立；必须结合 `#evidence` 看它依赖什么。

## 混合语法

`convince name (parameters) : P := by ...` 声明一个 `Convincing P`。
通常的 `intro`、`have`、`constructor`、`cases`、`rw`、`simp`、`exact` 等仍然在
普通命题目标上工作。新增操作只有：

```lean
-- 引入现有论证，局部得到一个条件假设。
have h ← otherArgument

-- 创建 Evidence，并引入条件假设。
evidence h : P := { id := "e1", explanation := "理由", source := "来源" }

-- 用 Evidence 关闭当前命题目标。
evidence { id := "e2", explanation := "理由", source := "来源" }
```

匿名/嵌套论证使用 `convincing% by ...`，并提供预期类型 `Convincing P`。
直接构造形式也可用 `convince named : P := Convincing.evidence ...`。
声明修饰符、显式和隐式参数沿用 Lean 的 `def`。

如果非形式化步骤本身依赖已有前提，不要把结论单独写成“无条件事实”。
显式声明该步骤的**条件**：

```lean
convince inferThrough (P Q : Prop) (premise : Convincing P) : Q := by
  have hp ← premise
  evidence step : P → Q := {
    id := "informal-step"
    explanation := "从 P 到 Q 的非形式化推理"
    source := "notes:argument"
  }
  exact step hp
```

## 内核与数据结构

`Evidence` 是小型来源记录：`id`、`explanation`、`source`。这些是作者提供的
信息，**不是签名、认证身份或已验证外部资源**。

`Convincing` 只有四种构造：

- `proof h`：真正的 `h : P`；
- `evidence e`：关于目标命题的非形式化依据；
- `mp rule premise`：保留规则论证和前提论证，两者缺一不可；
- `named name argument`：保留声明边界，便于递归反查。

`map` 应用一个真正的 Lean 蕴含，`both` 合并两个论证。
`evidenceLeaves` 返回有序的全部 Evidence 出现项，**不去重，也不因当前刚性
证明没用到某个显式引用就删掉它**。这是成功构建路径的保守依赖记录，不是最小依赖集。
失败并回退的 tactic 分支不留下记录。

`argument.Valid : Prop` 表达所有 Evidence 叶子对应的命题均成立。
内核检查的 `Convincing.sound` 只给出：

```lean
argument.Valid → P
```

因此不可能通过该接口无条件把 Evidence 转成 `P`。
`checked? : Convincing P → Option (PLift P)` 只在整棵树没有 Evidence 时提取
真正的证明；遇到任何 Evidence 返回 `none`。这个“无 Evidence”判断不替代公理审计。

## 为什么没有强塞一个 `Monad Convincing`

`do` 的核心组合依赖实际返回值。如果 `bind` 接受
`P → Convincing Q`，而前一步只提供关于 `P` 的 Evidence，就没有真正的 `P`
可传给 continuation。直接短路只保留第一份 Evidence，会丢失后续来源；
把 continuation 存起来，则一般无法在不提供 `P` 的情况下求得后续完整证据树。

这不是通过加日志能解决的问题。因此本原型采用**静态依赖组合（applicative 风格）**，
不宣称实现了通用 `Monad Convincing`，也不伪造 `LawfulMonad`。

混合 `by` 的 effect handler 运行在 Lean 自带的单子化 elaboration/tactic 环境中：
记录依赖 → 生成暂时的证明洞 → 用普通 tactics 检查推理 → 将所有洞抽象成前提 →
构造内核复核的条件规则及显式依赖树。journal 存在 Lean 的 metavariable context 中，
因此随正常的 tactic 回退一起回退，而不是不可回退的全局 `IO.Ref`。

普通 `do` 可以在 `Id`、`StateM`、`IO` 等真正的 Monad 里处理 **论证句柄**，
再用 `map` / `both` / `mp` 组合；但不能把 `Convincing P` 解包成真正的 `P`。
完整依赖式 effect/continuation 语义留给后续设计，不在此原型里偷偷近似。

## 溯源与信任边界

- `#evidence` 输出每一层的目标命题、命名论证、刚性规则、Evidence 文本和来源，
  并列出被查询项使用的全局公理。它使用结构归约，不调用 native evaluator 执行证据。
- `sorryAx`（包含经其他声明间接引入的 `sorry`）在 Convincer DSL 和查询中报错。
  普通 Lean 自定义公理仍属于用户选择的信任基础，会在查询里显示；没有把它们伪装成 Evidence。
- 内核库本身不引入 `axiom`、`sorry` 或 `unsafe`。`#evidence` 不是第三方 Lean
  插件/恶意元编程的安全沙箱，也不是来源真实性审计。
- 来源被设计为静态、可读的依赖。Evidence 的命题、元数据和输入论证不能依赖
  当前 tactic 块刚引入的局部假设、分支变量或未解决的 metavariable。
  可将数据参数提升到声明参数，或把依赖写成一个闭合的蕴含/全称命题。
  普通严格推理仍然可以任意使用局部假设。
- 归纳、分支推理可正常使用；在分支中引用独立的已有论证也受支持。这里没有实现
  “依赖一个未证存在命题，取出其见证，再运行任意程序以生成下一份 Evidence”。
- 查询遇到不能展开的 `opaque` 论证、真正依赖符号值分支的程序，或耗尽 Lean
  归约预算时会明确失败，不把部分结果宣称成完整来源。函数参数需要适当实例化。
- 命题目标限定为 `Prop`，**论证对象**在 `Type 1`；此版本不试图生成未经验证的
  `Nat` 等数据值。多个不同 Evidence 即使指向同一命题，也可以证明论证对象不同。

## 文件

- `Convincer/Core.lean`：纯数据、组合、条件可靠性和严格证明提取。
- `Convincer/Elab.lean`：混合语法、事务化 journal、全局溯源。
- `Convincer.lean`：公开 import。
- `Convincer/Tests.lean`：执行的正例与结构断言。
- `Convincer/check.py`：串行构建、溯源回执和负例门禁。
- `Convince/test.lean`：保留原路径，替换为可运行的迁移示例。

## SNL 收录状态

该功能在功能分支开发，`.SNL_Doc` 未修改。检查原始 `e234e87` 时，Toolkit 已报告
`Set.def.order.orderIsomorphism`、`Set.example.Nat`、`Set.preimageSet` 的悬空关系，
以及 `set-theory` Library 中缺失的 `Set.example.Nat` 节点。

按照 `FMNeco.md`，Lean 代码正式收录还需要对应的 SNL 条目/Pointer，主分支必须通过
`snl validate`。当前既有错误阻塞 Toolkit 写入前置门禁，所以这里交付的是**经过 Lean
验证的功能原型**，不是已完成 SNL 收录、可以直接合入主分支的内容发布。
未越权修复无关的集合论条目，也未将全库校验失败说成通过。
