module Cat.Category.Functor where

open import Agda.Primitive
open import Cubical
open import Function

open import Cat.Category

open Category hiding (_∘_)

module _ {ℓc ℓc' ℓd ℓd'} (ℂ : Category ℓc ℓc') (𝔻 : Category ℓd ℓd') where
  record IsFunctor
    (func* : Object ℂ → Object 𝔻)
    (func→ : {A B : Object ℂ} → ℂ [ A , B ] → 𝔻 [ func* A , func* B ])
      : Set (ℓc ⊔ ℓc' ⊔ ℓd ⊔ ℓd') where
    field
      ident   : {c : Object ℂ} → func→ (𝟙 ℂ {c}) ≡ 𝟙 𝔻 {func* c}
      -- TODO: Avoid use of ugly explicit arguments somehow.
      -- This guy managed to do it:
      --    https://github.com/copumpkin/categories/blob/master/Categories/Functor/Core.agda
      distrib : {A B C : Object ℂ} {f : ℂ [ A , B ]} {g : ℂ [ B , C ]}
        → func→ (ℂ [ g ∘ f ]) ≡ 𝔻 [ func→ g ∘ func→ f ]

  record Functor : Set (ℓc ⊔ ℓc' ⊔ ℓd ⊔ ℓd') where
    field
      func* : Object ℂ → Object 𝔻
      func→ : ∀ {A B} → ℂ [ A , B ] → 𝔻 [ func* A , func* B ]
      {{isFunctor}} : IsFunctor func* func→

open IsFunctor
open Functor

module _ {ℓ ℓ' : Level} {ℂ 𝔻 : Category ℓ ℓ'} where

  IsFunctor≡
    : {func* : Object ℂ → Object 𝔻}
      {func→ : {A B : Object ℂ} → ℂ [ A , B ] → 𝔻 [ func* A , func* B ]}
      {F G : IsFunctor ℂ 𝔻 func* func→}
    → (eqI
      : (λ i → ∀ {A} → func→ (𝟙 ℂ {A}) ≡ 𝟙 𝔻 {func* A})
        [ F .ident ≡ G .ident ])
    → (eqD :
        (λ i → ∀ {A B C} {f : ℂ [ A , B ]} {g : ℂ [ B , C ]}
          → func→ (ℂ [ g ∘ f ]) ≡ 𝔻 [ func→ g ∘ func→ f ])
        [ F .distrib ≡ G .distrib ])
    → (λ _ → IsFunctor ℂ 𝔻 (λ i → func* i) func→) [ F ≡ G ]
  IsFunctor≡ eqI eqD i = record { ident = eqI i ; distrib = eqD i }

  Functor≡ : {F G : Functor ℂ 𝔻}
    → (eq* : F .func* ≡ G .func*)
    → (eq→ : (λ i → ∀ {x y} → ℂ [ x , y ] → 𝔻 [ eq* i x , eq* i y ])
        [ F .func→ ≡ G .func→ ])
    -- → (eqIsF : PathP (λ i → IsFunctor ℂ 𝔻 (eq* i) (eq→ i)) (F .isFunctor) (G .isFunctor))
    → (eqIsFunctor : (λ i → IsFunctor ℂ 𝔻 (eq* i) (eq→ i)) [ F .isFunctor ≡ G .isFunctor ])
    → F ≡ G
  Functor≡ eq* eq→ eqIsFunctor i = record { func* = eq* i ; func→ = eq→ i ; isFunctor = eqIsFunctor i }

module _ {ℓ ℓ' : Level} {A B C : Category ℓ ℓ'} (F : Functor B C) (G : Functor A B) where
  private
    F* = F .func*
    F→ = F .func→
    G* = G .func*
    G→ = G .func→
    module _ {a0 a1 a2 : Object A} {α0 : A [ a0 , a1 ]} {α1 : A [ a1 , a2 ]} where

      dist : (F→ ∘ G→) (A [ α1 ∘ α0 ]) ≡ C [ (F→ ∘ G→) α1 ∘ (F→ ∘ G→) α0 ]
      dist = begin
        (F→ ∘ G→) (A [ α1 ∘ α0 ])         ≡⟨ refl ⟩
        F→ (G→ (A [ α1 ∘ α0 ]))           ≡⟨ cong F→ (G .isFunctor .distrib)⟩
        F→ (B [ G→ α1 ∘ G→ α0 ])          ≡⟨ F .isFunctor .distrib ⟩
        C [ (F→ ∘ G→) α1 ∘ (F→ ∘ G→) α0 ] ∎

  _∘f_ : Functor A C
  _∘f_ =
    record
      { func* = F* ∘ G*
      ; func→ = F→ ∘ G→
      ; isFunctor = record
        { ident = begin
          (F→ ∘ G→) (𝟙 A) ≡⟨ refl ⟩
          F→ (G→ (𝟙 A))   ≡⟨ cong F→ (G .isFunctor .ident)⟩
          F→ (𝟙 B)        ≡⟨ F .isFunctor .ident ⟩
          𝟙 C             ∎
        ; distrib = dist
        }
      }

-- The identity functor
identity : ∀ {ℓ ℓ'} → {C : Category ℓ ℓ'} → Functor C C
identity = record
  { func* = λ x → x
  ; func→ = λ x → x
  ; isFunctor = record
    { ident = refl
    ; distrib = refl
    }
  }
