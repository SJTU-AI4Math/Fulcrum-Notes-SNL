# Functional Programming — SNL Construction Blueprint

| Entry ID | Kind | Title | Parent |
|---|---|---|---|
| `FP.sec.monad` | section | Functional Programming: Monads | `—` |
| `FP.ctxt.1` | context | Types and type constructors | `FP.sec.monad` |
| `FP.ctxt.types` | context | $A, B, C$ | `FP.ctxt.1` |
| `FP.ctxt.M` | context | $M$ | `FP.ctxt.1` |
| `FP.ctxt.T` | context | $T$ | `FP.ctxt.1` |
| `FP.subsec.intro` | subsection | Standard Monad Instances | `FP.sec.monad` |
| `FP.subsec.basics` | subsection | Monad and Bind | `FP.sec.monad` |
| `FP.subsec.transformers` | subsection | Monad Transformers | `FP.sec.monad` |
| `FP.subsec.order` | subsection | Ordered and Lattice Monads | `FP.sec.monad` |
| `FP.subsec.instances` | subsection | Identity, Option, List, and Set | `FP.sec.monad` |
| `FP.def.monad` | definition | Monad | `FP.subsec.basics` |
| `FP.def.bind` | definition | Bind Operation | `FP.def.monad` |
| `FP.prop.leftIdentity` | property | Monad Law: Left Identity | `FP.def.monad` |
| `FP.prop.rightIdentity` | property | Monad Law: Right Identity | `FP.def.monad` |
| `FP.prop.associativity` | property | Monad Law: Associativity | `FP.def.monad` |
| `FP.def.map` | definition | Map Derived from Bind | `FP.def.bind` |
| `FP.def.flatten` | definition | Flatten Derived from Bind | `FP.def.bind` |
| `FP.def.monadTransformer` | definition | Monad Transformer | `FP.subsec.transformers` |
| `FP.def.lift` | definition | Lift Operation | `FP.def.monadTransformer` |
| `FP.prop.transformerLiftPure` | property | Lift Preserves Pure | `FP.def.lift` |
| `FP.prop.transformerLiftBind` | property | Lift Preserves Bind | `FP.def.lift` |
| `FP.def.monadOrder` | definition | Ordered Monad | `FP.subsec.order` |
| `FP.def.monadLattice` | definition | Monad Lattice | `FP.def.monadOrder` |
| `FP.prop.pureMonotone` | property | Pure is Monotone | `FP.def.monadOrder` |
| `FP.prop.bindMonotone` | property | Bind is Monotone | `FP.def.monadOrder` |
| `FP.prop.bindBottom` | property | Bottom is a Left Zero for Bind | `FP.def.monadLattice` |
| `FP.prop.bindSup` | property | Bind Distributes over Binary Join | `FP.def.monadLattice` |
| `FP.def.identity` | definition | Identity | `FP.subsec.instances` |
| `FP.prop.identityMonad` | property | Identity is a Monad | `FP.def.identity` |
| `FP.def.option` | definition | Option / Maybe | `FP.subsec.instances` |
| `FP.xmp.option` | example | Option / Maybe Monad | `FP.def.option` |
| `FP.def.list` | definition | List | `FP.subsec.instances` |
| `FP.prop.listMonad` | property | List is a Monad | `FP.def.list` |
| `FP.def.set` | definition | Set Monad | `FP.subsec.instances` |
| `FP.prop.setMonad` | property | Set is a Monad | `FP.def.set` |

## Terminology

Canonical namespace: `FP.*`. Core concepts: Monad, pure, bind, map, flatten, Monad Transformer, lift, Ordered Monad, Monad Lattice, Identity, Option/Maybe, List, Set.
