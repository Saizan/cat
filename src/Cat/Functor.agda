module Cat.Functor where

open import Agda.Primitive
open import Cubical
open import Function

open import Cat.Category

record Functor {ℓc ℓc' ℓd ℓd'} (C : Category ℓc ℓc') (D : Category ℓd ℓd')
  : Set (ℓc ⊔ ℓc' ⊔ ℓd ⊔ ℓd') where
  open Category
  field
    func* : C .Object → D .Object
    func→ : {dom cod : C .Object} → C .Arrow dom cod → D .Arrow (func* dom) (func* cod)
    ident   : { c : C .Object } → func→ (C .𝟙 {c}) ≡ D .𝟙 {func* c}
    -- TODO: Avoid use of ugly explicit arguments somehow.
    -- This guy managed to do it:
    --    https://github.com/copumpkin/categories/blob/master/Categories/Functor/Core.agda
    distrib : { c c' c'' : C .Object} {a : C .Arrow c c'} {a' : C .Arrow c' c''}
      → func→ (C ._⊕_ a' a) ≡ D ._⊕_ (func→ a') (func→ a)

open Functor
open Category

module _ {ℓ ℓ' : Level} {ℂ 𝔻 : Category ℓ ℓ'} where
  private
    _ℂ⊕_ = ℂ ._⊕_
  Functor≡ : {F G : Functor ℂ 𝔻}
    → (eq* : F .func* ≡ G .func*)
    → (eq→ : PathP (λ i → ∀ {x y} → ℂ .Arrow x y → 𝔻 .Arrow (eq* i x) (eq* i y))
      (F .func→) (G .func→))
    → (eqI : PathP (λ i → ∀ {A : ℂ .Object} → eq→ i (ℂ .𝟙 {A}) ≡ 𝔻 .𝟙 {eq* i A})
      (ident F) (ident G))
    → (eqD : PathP (λ i → {A B C : ℂ .Object} {f : ℂ .Arrow A B} {g : ℂ .Arrow B C}
      → eq→ i (ℂ ._⊕_ g f) ≡ 𝔻 ._⊕_ (eq→ i g) (eq→ i f))
      (distrib F) (distrib G))
    → F ≡ G
  Functor≡ eq* eq→ eqI eqD i = record { func* = eq* i ; func→ = eq→ i ; ident = eqI i ; distrib = eqD i }

module _ {ℓ ℓ' : Level} {A B C : Category ℓ ℓ'} (F : Functor B C) (G : Functor A B) where
  private
    F* = F .func*
    F→ = F .func→
    G* = G .func*
    G→ = G .func→
    _A⊕_ = A ._⊕_
    _B⊕_ = B ._⊕_
    _C⊕_ = C ._⊕_
    module _ {a0 a1 a2 : A .Object} {α0 : A .Arrow a0 a1} {α1 : A .Arrow a1 a2} where

      dist : (F→ ∘ G→) (α1 A⊕ α0) ≡ (F→ ∘ G→) α1 C⊕ (F→ ∘ G→) α0
      dist = begin
        (F→ ∘ G→) (α1 A⊕ α0)         ≡⟨ refl ⟩
        F→ (G→ (α1 A⊕ α0))           ≡⟨ cong F→ (G .distrib)⟩
        F→ ((G→ α1) B⊕ (G→ α0))      ≡⟨ F .distrib ⟩
        (F→ ∘ G→) α1 C⊕ (F→ ∘ G→) α0 ∎

  _∘f_ : Functor A C
  _∘f_ =
    record
      { func* = F* ∘ G*
      ; func→ = F→ ∘ G→
      ; ident = begin
        (F→ ∘ G→) (A .𝟙) ≡⟨ refl ⟩
        F→ (G→ (A .𝟙))   ≡⟨ cong F→ (G .ident)⟩
        F→ (B .𝟙)        ≡⟨ F .ident ⟩
        C .𝟙             ∎
      ; distrib = dist
      }

-- The identity functor
identity : ∀ {ℓ ℓ'} → {C : Category ℓ ℓ'} → Functor C C
identity = record
  { func* = λ x → x
  ; func→ = λ x → x
  ; ident = refl
  ; distrib = refl
  }
