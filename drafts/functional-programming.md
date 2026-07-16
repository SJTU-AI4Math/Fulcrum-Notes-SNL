# Functional Programming — corrected construction blueprint

Hierarchy: Section → Subsection → Entry → SubEntry (property/corollary/remark only).

| Entry | Kind | Parent |
|---|---|---|
| `FP.sec.monad` | section | `—` |
| `FP.ctxt.1` | context | `FP.sec.monad` |
| `FP.ctxt.types` | context | `FP.ctxt.1` |
| `FP.ctxt.M` | context | `FP.ctxt.1` |
| `FP.ctxt.T` | context | `FP.ctxt.1` |
| `FP.subsec.basics` | subsection | `FP.sec.monad` |
| `FP.subsec.transformers` | subsection | `FP.sec.monad` |
| `FP.subsec.order` | subsection | `FP.sec.monad` |
| `FP.subsec.instances` | subsection | `FP.sec.monad` |
| `FP.def.monad` | definition | `FP.subsec.basics` |
| `FP.def.bind` | property | `FP.subsec.basics` |
| `FP.prop.bind-equivalence` | property | `FP.def.monad` |
| `FP.prop.leftIdentity` | property | `FP.def.monad` |
| `FP.prop.rightIdentity` | property | `FP.def.monad` |
| `FP.prop.associativity` | property | `FP.def.monad` |
| `FP.def.map` | property | `FP.def.monad` |
| `FP.def.flatten` | property | `FP.def.monad` |
| `FP.def.monadTransformer` | definition | `FP.subsec.transformers` |
| `FP.def.lift` | definition | `FP.def.monadTransformer` |
| `FP.prop.transformerLiftPure` | property | `FP.def.monadTransformer` |
| `FP.prop.transformerLiftBind` | property | `FP.def.monadTransformer` |
| `FP.def.monadOrder` | definition | `FP.subsec.order` |
| `FP.def.monadLattice` | definition | `FP.subsec.order` |
| `FP.prop.pureMonotone` | property | `FP.def.monadOrder` |
| `FP.prop.bindMonotone` | property | `FP.def.monadOrder` |
| `FP.prop.bindBottom` | property | `FP.def.monadLattice` |
| `FP.prop.bindSup` | property | `FP.def.monadLattice` |
| `FP.def.identity` | definition | `FP.subsec.instances` |
| `FP.def.identityBind` | property | `FP.subsec.instances` |
| `FP.prop.identityMonad` | property | `FP.def.identity` |
| `FP.def.option` | definition | `FP.subsec.instances` |
| `FP.def.optionBind` | property | `FP.subsec.instances` |
| `FP.xmp.option` | example | `FP.subsec.instances` |
| `FP.def.list` | definition | `FP.subsec.instances` |
| `FP.def.listBind` | property | `FP.subsec.instances` |
| `FP.prop.listMonad` | property | `FP.def.list` |
| `FP.def.set` | definition | `FP.subsec.instances` |
| `FP.def.setBind` | property | `FP.subsec.instances` |
| `FP.prop.setMonad` | property | `FP.def.set` |
