module Data.DPair

import Decidable.Equality

%default total

namespace DPair

  public export
  curry : {0 p : a -> Type} -> ((x : a ** p x) -> c) -> (x : a) -> p x -> c
  curry f x y = f (x ** y)

  public export
  uncurry : {0 p : a -> Type} -> ((x : a) -> p x -> c) -> (x : a ** p x) -> c
  uncurry f s = f s.fst s.snd

  public export
  bimap : {0 p : a -> Type} -> {0 q : b -> Type} -> (f : a -> b) -> (forall x. p x -> q (f x)) -> (x : a ** p x) -> (y : b ** q y)
  bimap f g (x ** y) = (f x ** g y)

  public export
  DecEq k => ({x : k} -> Eq (v x)) => Eq (DPair k v) where
    (k1 ** v1) == (k2 ** v2) = case decEq k1 k2 of
                                 Yes Refl => v1 == v2
                                 No _     => False

namespace Exists

  ||| A dependent pair in which the first field (witness) should be
  ||| erased at runtime.
  |||
  ||| We can use `Exists` to construct dependent types in which the
  ||| type-level value is erased at runtime but used at compile time.
  ||| This type-level value could represent, for instance, a value
  ||| required for an intrinsic invariant required as part of the
  ||| dependent type's representation.
  |||
  ||| @type The type of the type-level value in the proof.
  ||| @this The dependent type that requires an instance of `type`.
  public export
  record Exists {0 type : Type} this where
    constructor Evidence
    0 fst : type
    snd : this fst

  public export
  curry : {0 p : a -> Type} -> (Exists p -> c) -> ({0 x : a} -> p x -> c)
  curry f = f . Evidence _

  public export
  uncurry : {0 p : a -> Type} -> ({0 x : a} -> p x -> c) -> Exists p -> c
  uncurry f ex = f ex.snd

  export
  evidenceInjectiveFst : Evidence x p = Evidence y q -> x = y
  evidenceInjectiveFst Refl = Refl

  export
  evidenceInjectiveSnd : Evidence x p = Evidence x q -> p = q
  evidenceInjectiveSnd Refl = Refl

  public export
  bimap : (0 f : a -> b) -> (forall x. p x -> q (f x)) -> Exists {type=a} p -> Exists {type=b} q
  bimap f g (Evidence x y) = Evidence (f x) (g y)

namespace Subset

  ||| A dependent pair in which the second field (evidence) should not
  ||| be required at runtime.
  |||
  ||| We can use `Subset` to provide extrinsic invariants about a
  ||| value and know that these invariants are erased at
  ||| runtime but used at compile time.
  |||
  ||| @type The type-level value's type.
  ||| @pred The dependent type that requires an instance of `type`.
  public export
  record Subset type pred where
    constructor Element
    fst : type
    0 snd : pred fst

  public export
  curry : {0 p : a -> Type} -> (Subset a p -> c) -> (x : a) -> (0 _ : p x) -> c
  curry f x y = f $ Element x y

  public export
  uncurry : {0 p : a -> Type} -> ((x : a) -> (0 _ : p x) -> c) -> Subset a p -> c
  uncurry f s = f s.fst s.snd

  export
  elementInjectiveFst : Element x p = Element y q -> x = y
  elementInjectiveFst Refl = Refl

  export
  elementInjectiveSnd : Element x p = Element x q -> p = q
  elementInjectiveSnd Refl = Refl

  public export
  bimap : (f : a -> b) -> (0 _ : forall x. p x -> q (f x)) -> Subset a p -> Subset b q
  bimap f g (Element x y) = Element (f x) (g y)

  public export
  Eq type => Eq (Subset type pred) where
    (==) = (==) `on` fst

  public export
  Ord type => Ord (Subset type pred) where
    compare = compare `on` fst

  ||| This Show implementation replaces the (erased) invariant
  ||| with an underscore.
  export
  Show type => Show (Subset type pred) where
    showPrec p (Element v _) = showCon p "Element" $ showArg v ++ " _"
