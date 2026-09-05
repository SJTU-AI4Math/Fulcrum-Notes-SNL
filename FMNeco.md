# Fulcrum's Math Notes Ecosystem

本文件作为 Fulcrum 数学笔记的规范。

写作的基本规范是，主分支任何提交必须保证可以通过 `snl validate` 检查，否则请先开分支后让 Agent 完成检查再提交。

## SNL-Lean 同步规范

1. 一个条目被 Fulcrum 笔记收容的标准是存在 SNL 条目。Lean 是可选项，而非必须项。

2. Lean 文件中的代码必须在 SNL 文件中有恰当的条目指向该位置。这不仅包括常量声明，也包括记号、语境、元编程程序等等。即：接受有 SNL 而无 Lean，但不接受有 Lean 而无 SNL。

## ID 命名规范
*此处 Mathlib 泛指 v4.28.0 下的 Lean 标准库 + Mathlib*

* **Mathlib 兼容边界**：
  1. 若一个宏所指称的概念与 Mathlib 中的某个概念完全一致，则严格采用 Mathlib 中的完整 Lean 常量名。
  2. 若一个条目所指称的概念与 Mathlib 中的某个概念完全一致，则采用 `Mathlib.<条目类别标签>.<完整 Lean 常量名>`。
  3. 不允许一个与 Mathlib 概念不一致，但名称与 Mathlib 中常量

* **若一个概念与 Mathlib 无法直接对齐，则正常命名**：
  1. 若一个宏所指称的概念与 Mathlib 中的某个概念不一致，则采用 `<所属领域缩写>.<条目类别标签>.<正式名称>`。

## 宏格式规范
