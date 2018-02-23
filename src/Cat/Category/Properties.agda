{-# OPTIONS --allow-unsolved-metas --cubical #-}

module Cat.Category.Properties where

open import Agda.Primitive
open import Data.Product
open import Cubical

open import Cat.Category
open import Cat.Category.Functor
open import Cat.Categories.Sets
open import Cat.Equality
open Equality.Data.Product

module _ {ℓ ℓ' : Level} {ℂ : Category ℓ ℓ'} { A B : Category.Object ℂ } {X : Category.Object ℂ} (f : Category.Arrow ℂ A B) where
  open Category ℂ

  iso-is-epi : Isomorphism f → Epimorphism {X = X} f
  iso-is-epi (f- , left-inv , right-inv) g₀ g₁ eq = begin
    g₀              ≡⟨ sym (proj₁ ident) ⟩
    g₀ ∘ 𝟙          ≡⟨ cong (_∘_ g₀) (sym right-inv) ⟩
    g₀ ∘ (f ∘ f-)   ≡⟨ isAssociative ⟩
    (g₀ ∘ f) ∘ f-   ≡⟨ cong (λ φ → φ ∘ f-) eq ⟩
    (g₁ ∘ f) ∘ f-   ≡⟨ sym isAssociative ⟩
    g₁ ∘ (f ∘ f-)   ≡⟨ cong (_∘_ g₁) right-inv ⟩
    g₁ ∘ 𝟙          ≡⟨ proj₁ ident ⟩
    g₁              ∎

  iso-is-mono : Isomorphism f → Monomorphism {X = X} f
  iso-is-mono (f- , (left-inv , right-inv)) g₀ g₁ eq =
    begin
    g₀            ≡⟨ sym (proj₂ ident) ⟩
    𝟙 ∘ g₀        ≡⟨ cong (λ φ → φ ∘ g₀) (sym left-inv) ⟩
    (f- ∘ f) ∘ g₀ ≡⟨ sym isAssociative ⟩
    f- ∘ (f ∘ g₀) ≡⟨ cong (_∘_ f-) eq ⟩
    f- ∘ (f ∘ g₁) ≡⟨ isAssociative ⟩
    (f- ∘ f) ∘ g₁ ≡⟨ cong (λ φ → φ ∘ g₁) left-inv ⟩
    𝟙 ∘ g₁        ≡⟨ proj₂ ident ⟩
    g₁            ∎

  iso-is-epi-mono : Isomorphism f → Epimorphism {X = X} f × Monomorphism {X = X} f
  iso-is-epi-mono iso = iso-is-epi iso , iso-is-mono iso

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
      eqTrans = funExt λ x → funExt λ x → ℂ.ident .proj₂

      open import Cubical.NType.Properties
      open import Cat.Categories.Fun
      :ident: : :func→: (ℂ.𝟙 {c}) ≡ Category.𝟙 Fun {A = prshf c}
      :ident: = lemSig (naturalIsProp {F = prshf c} {prshf c}) _ _ eq
        where
          eq : (λ C x → ℂ [ ℂ.𝟙 ∘ x ]) ≡ identityTrans (prshf c)
          eq = funExt λ A → funExt λ B → proj₂ ℂ.ident

  yoneda : Functor ℂ (Fun {ℂ = Opposite ℂ} {𝔻 = 𝓢})
  yoneda = record
    { raw = record
      { func* = prshf
      ; func→ = :func→:
      }
    ; isFunctor = record
      { ident = :ident:
      ; distrib = {!!}
      }
    }
