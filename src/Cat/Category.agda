{-# OPTIONS --allow-unsolved-metas --cubical #-}

module Cat.Category where

open import Agda.Primitive
open import Data.Unit.Base
open import Data.Product renaming
  ( proj₁ to fst
  ; proj₂ to snd
  ; ∃! to ∃!≈
  )
open import Data.Empty
import Function
open import Cubical
open import Cubical.GradLemma using ( propIsEquiv )

∃! : ∀ {a b} {A : Set a}
  → (A → Set b) → Set (a ⊔ b)
∃! = ∃!≈ _≡_

∃!-syntax : ∀ {a b} {A : Set a} → (A → Set b) → Set (a ⊔ b)
∃!-syntax = ∃

syntax ∃!-syntax (λ x → B) = ∃![ x ] B

record RawCategory (ℓ ℓ' : Level) : Set (lsuc (ℓ' ⊔ ℓ)) where
  -- adding no-eta-equality can speed up type-checking.
  -- ONLY IF you define your categories with copatterns though.
  no-eta-equality
  field
    -- Need something like:
    -- Object : Σ (Set ℓ) isGroupoid
    Object : Set ℓ
    -- And:
    -- Arrow  : Object → Object → Σ (Set ℓ') isSet
    Arrow  : Object → Object → Set ℓ'
    𝟙      : {o : Object} → Arrow o o
    _∘_    : {A B C : Object} → Arrow B C → Arrow A B → Arrow A C
  infixl 10 _∘_
  domain : { a b : Object } → Arrow a b → Object
  domain {a = a} _ = a
  codomain : { a b : Object } → Arrow a b → Object
  codomain {b = b} _ = b

-- Thierry: All projections must be `isProp`'s

-- According to definitions 9.1.1 and 9.1.6 in the HoTT book the
-- arrows of a category form a set (arrow-is-set), and there is an
-- equivalence between the equality of objects and isomorphisms
-- (univalent).
record IsCategory {ℓa ℓb : Level} (ℂ : RawCategory ℓa ℓb) : Set (lsuc (ℓa ⊔ ℓb)) where
  open RawCategory ℂ
  -- (Object : Set ℓ)
  -- (Arrow  : Object → Object → Set ℓ')
  -- (𝟙      : {o : Object} → Arrow o o)
  -- (_∘_    : { a b c : Object } → Arrow b c → Arrow a b → Arrow a c)
  field
    assoc : {A B C D : Object} { f : Arrow A B } { g : Arrow B C } { h : Arrow C D }
      → h ∘ (g ∘ f) ≡ (h ∘ g) ∘ f
    ident : {A B : Object} {f : Arrow A B}
      → f ∘ 𝟙 ≡ f × 𝟙 ∘ f ≡ f
    arrow-is-set : ∀ {A B : Object} → isSet (Arrow A B)

  Isomorphism : ∀ {A B} → (f : Arrow A B) → Set ℓb
  Isomorphism {A} {B} f = Σ[ g ∈ Arrow B A ] g ∘ f ≡ 𝟙 × f ∘ g ≡ 𝟙

  _≅_ : (A B : Object) → Set ℓb
  _≅_ A B = Σ[ f ∈ Arrow A B ] (Isomorphism f)

  idIso : (A : Object) → A ≅ A
  idIso A = 𝟙 , (𝟙 , ident)

  id-to-iso : (A B : Object) → A ≡ B → A ≅ B
  id-to-iso A B eq = transp (\ i → A ≅ eq i) (idIso A)


  -- TODO: might want to implement isEquiv differently, there are 3
  -- equivalent formulations in the book.
  field
    univalent : {A B : Object} → isEquiv (A ≡ B) (A ≅ B) (id-to-iso A B)

  module _ {A B : Object} where
    Epimorphism : {X : Object } → (f : Arrow A B) → Set ℓb
    Epimorphism {X} f = ( g₀ g₁ : Arrow B X ) → g₀ ∘ f ≡ g₁ ∘ f → g₀ ≡ g₁

    Monomorphism : {X : Object} → (f : Arrow A B) → Set ℓb
    Monomorphism {X} f = ( g₀ g₁ : Arrow X A ) → f ∘ g₀ ≡ f ∘ g₁ → g₀ ≡ g₁

module _ {ℓa} {ℓb} {ℂ : RawCategory ℓa ℓb} where
  -- TODO, provable by using  arrow-is-set and that isProp (isEquiv _ _ _)
  -- This lemma will be useful to prove the equality of two categories.
  IsCategory-is-prop : isProp (IsCategory ℂ)
  IsCategory-is-prop x y i = record
    { assoc = x.arrow-is-set _ _ x.assoc y.assoc i
    ; ident =
      ( x.arrow-is-set _ _ (fst x.ident) (fst y.ident) i
      , x.arrow-is-set _ _ (snd x.ident) (snd y.ident) i
      )
    -- ; arrow-is-set = {!λ x₁ y₁ p q → x.arrow-is-set _ _ p q!}
    ; arrow-is-set = λ _ _ p q →
      let
        golden : x.arrow-is-set _ _ p q ≡ y.arrow-is-set _ _ p q
        golden = λ j k l → {!!}
      in
        golden i
      ; univalent = λ y₁ → {!!}
    }
    where
      module x = IsCategory x
      module y = IsCategory y

Category : (ℓa ℓb : Level) → Set (lsuc (ℓa ⊔ ℓb))
Category ℓa ℓb = Σ (RawCategory ℓa ℓb) IsCategory

module Category {ℓa ℓb : Level} (ℂ : Category ℓa ℓb) where
  raw = fst ℂ
  open RawCategory raw public
  isCategory = snd ℂ

open RawCategory

-- _∈_ : ∀ {ℓa ℓb} (ℂ : Category ℓa ℓb) → (ℂ .fst .Object → Set ℓb) → Set (ℓa ⊔ ℓb)
-- A ∈ ℂ =

Obj : ∀ {ℓa ℓb} → Category ℓa ℓb → Set ℓa
Obj ℂ = ℂ .fst .Object

_[_,_] : ∀ {ℓ ℓ'} → (ℂ : Category ℓ ℓ') → (A : Obj ℂ) → (B : Obj ℂ) → Set ℓ'
ℂ [ A , B ] = ℂ .fst .Arrow A B

_[_∘_] : ∀ {ℓ ℓ'} → (ℂ : Category ℓ ℓ') → {A B C : Obj ℂ} → (g : ℂ [ B , C ]) → (f : ℂ [ A , B ]) → ℂ [ A , C ]
ℂ [ g ∘ f ] = ℂ .fst ._∘_ g f

module _ {ℓ ℓ' : Level} (ℂ : Category ℓ ℓ') {A B obj : Obj ℂ} where
  IsProduct : (π₁ : ℂ [ obj , A ]) (π₂ : ℂ [ obj , B ]) → Set (ℓ ⊔ ℓ')
  IsProduct π₁ π₂
    = ∀ {X : Obj ℂ} (x₁ : ℂ [ X , A ]) (x₂ : ℂ [ X , B ])
    → ∃![ x ] (ℂ [ π₁ ∘ x ] ≡ x₁ × ℂ [ π₂ ∘ x ] ≡ x₂)

-- Tip from Andrea; Consider this style for efficiency:
-- record IsProduct {ℓ ℓ' : Level} (ℂ : Category {ℓ} {ℓ'})
--   {A B obj : Object ℂ} (π₁ : Arrow ℂ obj A) (π₂ : Arrow ℂ obj B) : Set (ℓ ⊔ ℓ') where
--   field
--      isProduct : ∀ {X : ℂ .Object} (x₁ : ℂ .Arrow X A) (x₂ : ℂ .Arrow X B)
--        → ∃![ x ] (ℂ ._⊕_ π₁ x ≡ x₁ × ℂ. _⊕_ π₂ x ≡ x₂)

record Product {ℓ ℓ' : Level} {ℂ : Category ℓ ℓ'} (A B : Obj ℂ) : Set (ℓ ⊔ ℓ') where
  no-eta-equality
  field
    obj : Obj ℂ
    proj₁ : ℂ [ obj , A ]
    proj₂ : ℂ [ obj , B ]
    {{isProduct}} : IsProduct ℂ proj₁ proj₂

  arrowProduct : ∀ {X} → (π₁ : ℂ [ X , A ]) (π₂ : ℂ [ X , B ])
    → ℂ [ X , obj ]
  arrowProduct π₁ π₂ = fst (isProduct π₁ π₂)

record HasProducts {ℓ ℓ' : Level} (ℂ : Category ℓ ℓ') : Set (ℓ ⊔ ℓ') where
  field
    product : ∀ (A B : Obj ℂ) → Product {ℂ = ℂ} A B

  open Product

  objectProduct : (A B : Obj ℂ) → Obj ℂ
  objectProduct A B = Product.obj (product A B)
  -- The product mentioned in awodey in Def 6.1 is not the regular product of arrows.
  -- It's a "parallel" product
  parallelProduct : {A A' B B' : Obj ℂ} → ℂ [ A , A' ] → ℂ [ B , B' ]
    → ℂ [ objectProduct A B , objectProduct A' B' ]
  parallelProduct {A = A} {A' = A'} {B = B} {B' = B'} a b = arrowProduct (product A' B')
    (ℂ [ a ∘ (product A B) .proj₁ ])
    (ℂ [ b ∘ (product A B) .proj₂ ])

module _ {ℓa ℓb : Level} (ℂ : Category ℓa ℓb) where
  private
    open Category ℂ
    module ℂ = RawCategory (ℂ .fst)
    OpRaw : RawCategory ℓa ℓb
    OpRaw = record
      { Object = ℂ.Object
      ; Arrow = Function.flip ℂ.Arrow
      ; 𝟙 = ℂ.𝟙
      ; _∘_ = Function.flip (ℂ._∘_)
      }
    open IsCategory isCategory
    OpIsCategory : IsCategory OpRaw
    OpIsCategory = record
      { assoc = sym assoc
      ; ident = swap ident
      ; arrow-is-set = {!!}
      ; univalent = {!!}
      }
  Opposite : Category ℓa ℓb
  Opposite = OpRaw , OpIsCategory

-- A consequence of no-eta-equality; `Opposite-is-involution` is no longer
-- definitional - i.e.; you must match on the fields:
--
-- Opposite-is-involution : ∀ {ℓ ℓ'} → {C : Category {ℓ} {ℓ'}} → Opposite (Opposite C) ≡ C
-- Object (Opposite-is-involution {C = C} i) = Object C
-- Arrow (Opposite-is-involution i) = {!!}
-- 𝟙 (Opposite-is-involution i) = {!!}
-- _⊕_ (Opposite-is-involution i) = {!!}
-- assoc (Opposite-is-involution i) = {!!}
-- ident (Opposite-is-involution i) = {!!}

module _ {ℓ ℓ'} (ℂ : Category ℓ ℓ') {{hasProducts : HasProducts ℂ}} where
  open HasProducts hasProducts
  open Product hiding (obj)
  private
    _×p_ : (A B : Obj ℂ) → Obj ℂ
    _×p_ A B = Product.obj (product A B)

  module _ (B C : Obj ℂ) where
    IsExponential : (Cᴮ : Obj ℂ) → ℂ [ Cᴮ ×p B , C ] → Set (ℓ ⊔ ℓ')
    IsExponential Cᴮ eval = ∀ (A : Obj ℂ) (f : ℂ [ A ×p B , C ])
      → ∃![ f~ ] (ℂ [ eval ∘ parallelProduct f~ (Category.raw ℂ .𝟙)] ≡ f)

    record Exponential : Set (ℓ ⊔ ℓ') where
      field
        -- obj ≡ Cᴮ
        obj : Obj ℂ
        eval : ℂ [ obj ×p B , C ]
        {{isExponential}} : IsExponential obj eval
      -- If I make this an instance-argument then the instance resolution
      -- algorithm goes into an infinite loop. Why?
      exponentialsHaveProducts : HasProducts ℂ
      exponentialsHaveProducts = hasProducts
      transpose : (A : Obj ℂ) → ℂ [ A ×p B , C ] → ℂ [ A , obj ]
      transpose A f = fst (isExponential A f)

record HasExponentials {ℓ ℓ' : Level} (ℂ : Category ℓ ℓ') {{_ : HasProducts ℂ}} : Set (ℓ ⊔ ℓ') where
  field
    exponent : (A B : Obj ℂ) → Exponential ℂ A B

record CartesianClosed {ℓ ℓ' : Level} (ℂ : Category ℓ ℓ') : Set (ℓ ⊔ ℓ') where
  field
    {{hasProducts}}     : HasProducts ℂ
    {{hasExponentials}} : HasExponentials ℂ

module _ {ℓa ℓb : Level} (ℂ : Category ℓa ℓb) where
  unique = isContr

  IsInitial : Obj ℂ → Set (ℓa ⊔ ℓb)
  IsInitial I = {X : Obj ℂ} → unique (ℂ [ I , X ])

  IsTerminal : Obj ℂ → Set (ℓa ⊔ ℓb)
  -- ∃![ ? ] ?
  IsTerminal T = {X : Obj ℂ} → unique (ℂ [ X , T ])

  Initial : Set (ℓa ⊔ ℓb)
  Initial = Σ (Obj ℂ) IsInitial

  Terminal : Set (ℓa ⊔ ℓb)
  Terminal = Σ (Obj ℂ) IsTerminal
