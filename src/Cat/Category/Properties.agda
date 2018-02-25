{-# OPTIONS --allow-unsolved-metas --cubical #-}

module Cat.Category.Properties where

open import Agda.Primitive
open import Data.Product
open import Cubical

open import Cat.Category
open import Cat.Category.Functor
open import Cat.Equality
open Equality.Data.Product

-- TODO: We want to avoid defining the yoneda embedding going through the
-- category of categories (since it doesn't exist).
open import Cat.Categories.Cat using (RawCat)

module _ {ℓ : Level} {ℂ : Category ℓ ℓ} (unprovable : IsCategory (RawCat ℓ ℓ)) where
  open import Cat.Categories.Fun
  open import Cat.Categories.Sets
  module Cat = Cat.Categories.Cat
  open import Cat.Category.Exponential
  open Functor
  𝓢 = Sets ℓ
  open Fun (opposite ℂ) 𝓢
  private
    Catℓ : Category _ _
    Catℓ = record { raw = RawCat ℓ ℓ ; isCategory = unprovable}
    prshf = presheaf {ℂ = ℂ}
    module ℂ = Category ℂ

    _⇑_ : (A B : Category.Object Catℓ) → Category.Object Catℓ
    A ⇑ B = (exponent A B) .obj
      where
        open HasExponentials (Cat.hasExponentials ℓ unprovable)

    module _ {A B : ℂ.Object} (f : ℂ [ A , B ]) where
      :func→: : NaturalTransformation (prshf A) (prshf B)
      :func→: = (λ C x → ℂ [ f ∘ x ]) , λ f₁ → funExt λ _ → ℂ.isAssociative

    module _ {c : Category.Object ℂ} where
      eqTrans : (λ _ → Transformation (prshf c) (prshf c))
        [ (λ _ x → ℂ [ ℂ.𝟙 ∘ x ]) ≡ identityTrans (prshf c) ]
      eqTrans = funExt λ x → funExt λ x → ℂ.isIdentity .proj₂

      open import Cubical.NType.Properties
      open import Cat.Categories.Fun
      :ident: : :func→: (ℂ.𝟙 {c}) ≡ Category.𝟙 Fun {A = prshf c}
      :ident: = lemSig (naturalIsProp {F = prshf c} {prshf c}) _ _ eq
        where
          eq : (λ C x → ℂ [ ℂ.𝟙 ∘ x ]) ≡ identityTrans (prshf c)
          eq = funExt λ A → funExt λ B → proj₂ ℂ.isIdentity

  yoneda : Functor ℂ Fun
  yoneda = record
    { raw = record
      { func* = prshf
      ; func→ = :func→:
      }
    ; isFunctor = record
      { isIdentity = :ident:
      ; isDistributive = {!!}
      }
    }
