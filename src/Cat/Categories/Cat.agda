-- There is no category of categories in our interpretation
{-# OPTIONS --cubical --allow-unsolved-metas #-}

module Cat.Categories.Cat where

open import Cat.Prelude renaming (proj₁ to fst ; proj₂ to snd)

open import Cubical
open import Cubical.Sigma

open import Cat.Category
open import Cat.Category.Functor
open import Cat.Category.Product
open import Cat.Category.Exponential hiding (_×_ ; product)
open import Cat.Category.NaturalTransformation
open import Cat.Categories.Fun

open import Cat.Equality
open Equality.Data.Product

-- The category of categories
module _ (ℓ ℓ' : Level) where
  private
    module _ {𝔸 𝔹 ℂ 𝔻 : Category ℓ ℓ'} {F : Functor 𝔸 𝔹} {G : Functor 𝔹 ℂ} {H : Functor ℂ 𝔻} where
      assc : F[ H ∘ F[ G ∘ F ] ] ≡ F[ F[ H ∘ G ] ∘ F ]
      assc = Functor≡ refl

    module _ {ℂ 𝔻 : Category ℓ ℓ'} {F : Functor ℂ 𝔻} where
      ident-r : F[ F ∘ identity ] ≡ F
      ident-r = Functor≡ refl

      ident-l : F[ identity ∘ F ] ≡ F
      ident-l = Functor≡ refl

  RawCat : RawCategory (lsuc (ℓ ⊔ ℓ')) (ℓ ⊔ ℓ')
  RawCategory.Object RawCat = Category ℓ ℓ'
  RawCategory.Arrow  RawCat = Functor
  RawCategory.𝟙      RawCat = identity
  RawCategory._∘_    RawCat = F[_∘_]

  private
    open RawCategory RawCat
    isAssociative : IsAssociative
    isAssociative {f = F} {G} {H} = assc {F = F} {G = G} {H = H}

    isIdentity : IsIdentity identity
    isIdentity = ident-l , ident-r

  -- NB! `ArrowsAreSets RawCat` is *not* provable. The type of functors,
  -- however, form a groupoid! Therefore there is no (1-)category of
  -- categories. There does, however, exist a 2-category of 1-categories.
  --
  -- Because of this there is no category of categories.
  Cat : (unprovable : IsCategory RawCat) → Category (lsuc (ℓ ⊔ ℓ')) (ℓ ⊔ ℓ')
  Category.raw        (Cat _)          = RawCat
  Category.isCategory (Cat unprovable) = unprovable

-- | In the following we will pretend there is a category of categories when
-- e.g. talking about it being cartesian closed. It still makes sense to
-- construct these things even though that category does not exist.
--
-- If the notion of a category is later generalized to work on different
-- homotopy levels, then the proof that the category of categories is cartesian
-- closed will follow immediately from these constructions.

-- | the category of categories have products.
module CatProduct {ℓ ℓ' : Level} (ℂ 𝔻 : Category ℓ ℓ') where
  private
    module ℂ = Category ℂ
    module 𝔻 = Category 𝔻

    module _ where
      private
        Obj = ℂ.Object × 𝔻.Object
        Arr  : Obj → Obj → Set ℓ'
        Arr (c , d) (c' , d') = ℂ [ c , c' ] × 𝔻 [ d , d' ]
        𝟙 : {o : Obj} → Arr o o
        𝟙 = ℂ.𝟙 , 𝔻.𝟙
        _∘_ :
          {a b c : Obj} →
          Arr b c →
          Arr a b →
          Arr a c
        _∘_ = λ { (bc∈C , bc∈D) (ab∈C , ab∈D) → ℂ [ bc∈C ∘ ab∈C ] , 𝔻 [ bc∈D ∘ ab∈D ]}

      rawProduct : RawCategory ℓ ℓ'
      RawCategory.Object rawProduct = Obj
      RawCategory.Arrow  rawProduct = Arr
      RawCategory.𝟙      rawProduct = 𝟙
      RawCategory._∘_    rawProduct = _∘_

    open RawCategory rawProduct

    arrowsAreSets : ArrowsAreSets
    arrowsAreSets = setSig {sA = ℂ.arrowsAreSets} {sB = λ x → 𝔻.arrowsAreSets}
    isIdentity : IsIdentity 𝟙
    isIdentity
      = Σ≡ (fst ℂ.isIdentity) (fst 𝔻.isIdentity)
      , Σ≡ (snd ℂ.isIdentity) (snd 𝔻.isIdentity)

    postulate univalent : Univalence.Univalent isIdentity
    instance
      isCategory : IsCategory rawProduct
      IsCategory.isAssociative isCategory = Σ≡ ℂ.isAssociative 𝔻.isAssociative
      IsCategory.isIdentity    isCategory = isIdentity
      IsCategory.arrowsAreSets isCategory = arrowsAreSets
      IsCategory.univalent     isCategory = univalent

  object : Category ℓ ℓ'
  Category.raw object = rawProduct

  proj₁ : Functor object ℂ
  proj₁ = record
    { raw = record
      { omap = fst ; fmap = fst }
    ; isFunctor = record
      { isIdentity = refl ; isDistributive = refl }
    }

  proj₂ : Functor object 𝔻
  proj₂ = record
    { raw = record
      { omap = snd ; fmap = snd }
    ; isFunctor = record
      { isIdentity = refl ; isDistributive = refl }
    }

  module _ {X : Category ℓ ℓ'} (x₁ : Functor X ℂ) (x₂ : Functor X 𝔻) where
    private
      x : Functor X object
      x = record
        { raw = record
          { omap = λ x → x₁.omap x , x₂.omap x
          ; fmap = λ x → x₁.fmap x , x₂.fmap x
          }
        ; isFunctor = record
          { isIdentity     = Σ≡ x₁.isIdentity x₂.isIdentity
          ; isDistributive = Σ≡ x₁.isDistributive x₂.isDistributive
          }
        }
        where
          open module x₁ = Functor x₁
          open module x₂ = Functor x₂

      isUniqL : F[ proj₁ ∘ x ] ≡ x₁
      isUniqL = Functor≡ refl

      isUniqR : F[ proj₂ ∘ x ] ≡ x₂
      isUniqR = Functor≡ refl

      isUniq : F[ proj₁ ∘ x ] ≡ x₁ × F[ proj₂ ∘ x ] ≡ x₂
      isUniq = isUniqL , isUniqR

    isProduct : ∃![ x ] (F[ proj₁ ∘ x ] ≡ x₁ × F[ proj₂ ∘ x ] ≡ x₂)
    isProduct = x , isUniq

module _ {ℓ ℓ' : Level} (unprovable : IsCategory (RawCat ℓ ℓ')) where
  private
    Catℓ = Cat ℓ ℓ' unprovable

  module _ (ℂ 𝔻 : Category ℓ ℓ') where
    private
      module P = CatProduct ℂ 𝔻

      rawProduct : RawProduct Catℓ ℂ 𝔻
      RawProduct.object rawProduct = P.object
      RawProduct.proj₁  rawProduct = P.proj₁
      RawProduct.proj₂  rawProduct = P.proj₂

      isProduct : IsProduct Catℓ _ _ rawProduct
      IsProduct.ump isProduct = P.isProduct

    product : Product Catℓ ℂ 𝔻
    Product.raw       product = rawProduct
    Product.isProduct product = isProduct

  instance
    hasProducts : HasProducts Catℓ
    hasProducts = record { product = product }

-- | The category of categories have expoentntials - and because it has products
-- it is therefory also cartesian closed.
module CatExponential {ℓ : Level} (ℂ 𝔻 : Category ℓ ℓ) where
  private
    module ℂ = Category ℂ
    module 𝔻 = Category 𝔻
    Categoryℓ = Category ℓ ℓ
    open Fun ℂ 𝔻 renaming (identity to idN)

    omap : Functor ℂ 𝔻 × ℂ.Object → 𝔻.Object
    omap (F , A) = Functor.omap F A

  -- The exponential object
  object : Categoryℓ
  object = Fun

  module _ {dom cod : Functor ℂ 𝔻 × ℂ.Object} where
    open Σ dom renaming (proj₁ to F ; proj₂ to A)
    open Σ cod renaming (proj₁ to G ; proj₂ to B)
    private
      module F = Functor F
      module G = Functor G

    fmap : (pobj : NaturalTransformation F G × ℂ [ A , B ])
      → 𝔻 [ F.omap A , G.omap B ]
    fmap ((θ , θNat) , f) = 𝔻 [ θ B ∘ F.fmap f ]
    -- Alternatively:
    --
    --   fmap ((θ , θNat) , f) = 𝔻 [ G.fmap f ∘ θ A ]
    --
    -- Since they are equal by naturality of θ.

  open CatProduct renaming (object to _⊗_) using ()

  module _ {c : Functor ℂ 𝔻 × ℂ.Object} where
    open Σ c renaming (proj₁ to F ; proj₂ to C)

    ident : fmap {c} {c} (NT.identity F , ℂ.𝟙 {A = snd c}) ≡ 𝔻.𝟙
    ident = begin
      fmap {c} {c} (Category.𝟙 (object ⊗ ℂ) {c})        ≡⟨⟩
      fmap {c} {c} (idN F , ℂ.𝟙)               ≡⟨⟩
      𝔻 [ identityTrans F C ∘ F.fmap ℂ.𝟙 ]    ≡⟨⟩
      𝔻 [ 𝔻.𝟙 ∘ F.fmap ℂ.𝟙 ]                  ≡⟨ 𝔻.leftIdentity ⟩
      F.fmap ℂ.𝟙                               ≡⟨ F.isIdentity ⟩
      𝔻.𝟙                                       ∎
      where
        module F = Functor F

  module _ {F×A G×B H×C : Functor ℂ 𝔻 × ℂ.Object} where
    open Σ F×A renaming (proj₁ to F ; proj₂ to A)
    open Σ G×B renaming (proj₁ to G ; proj₂ to B)
    open Σ H×C renaming (proj₁ to H ; proj₂ to C)
    private
      module F = Functor F
      module G = Functor G
      module H = Functor H

    module _
      {θ×f : NaturalTransformation F G × ℂ [ A , B ]}
      {η×g : NaturalTransformation G H × ℂ [ B , C ]} where
      open Σ θ×f renaming (proj₁ to θNT ; proj₂ to f)
      open Σ θNT renaming (proj₁ to θ   ; proj₂ to θNat)
      open Σ η×g renaming (proj₁ to ηNT ; proj₂ to g)
      open Σ ηNT renaming (proj₁ to η   ; proj₂ to ηNat)
      private
        ηθNT : NaturalTransformation F H
        ηθNT = NT[_∘_] {F} {G} {H} ηNT θNT
      open Σ ηθNT renaming (proj₁ to ηθ   ; proj₂ to ηθNat)

      isDistributive :
          𝔻 [ 𝔻 [ η C ∘ θ C ] ∘ F.fmap ( ℂ [ g ∘ f ] ) ]
        ≡ 𝔻 [ 𝔻 [ η C ∘ G.fmap g ] ∘ 𝔻 [ θ B ∘ F.fmap f ] ]
      isDistributive = begin
        𝔻 [ (ηθ C) ∘ F.fmap (ℂ [ g ∘ f ]) ]
          ≡⟨ ηθNat (ℂ [ g ∘ f ]) ⟩
        𝔻 [ H.fmap (ℂ [ g ∘ f ]) ∘ (ηθ A) ]
          ≡⟨ cong (λ φ → 𝔻 [ φ ∘ ηθ A ]) (H.isDistributive) ⟩
        𝔻 [ 𝔻 [ H.fmap g ∘ H.fmap f ] ∘ (ηθ A) ]
          ≡⟨ sym 𝔻.isAssociative ⟩
        𝔻 [ H.fmap g ∘ 𝔻 [ H.fmap f ∘ ηθ A ] ]
          ≡⟨ cong (λ φ → 𝔻 [ H.fmap g ∘ φ ]) 𝔻.isAssociative ⟩
        𝔻 [ H.fmap g ∘ 𝔻 [ 𝔻 [ H.fmap f ∘ η A ] ∘ θ A ] ]
          ≡⟨ cong (λ φ → 𝔻 [ H.fmap g ∘ φ ]) (cong (λ φ → 𝔻 [ φ ∘ θ A ]) (sym (ηNat f))) ⟩
        𝔻 [ H.fmap g ∘ 𝔻 [ 𝔻 [ η B ∘ G.fmap f ] ∘ θ A ] ]
          ≡⟨ cong (λ φ → 𝔻 [ H.fmap g ∘ φ ]) (sym 𝔻.isAssociative) ⟩
        𝔻 [ H.fmap g ∘ 𝔻 [ η B ∘ 𝔻 [ G.fmap f ∘ θ A ] ] ]
          ≡⟨ 𝔻.isAssociative ⟩
        𝔻 [ 𝔻 [ H.fmap g ∘ η B ] ∘ 𝔻 [ G.fmap f ∘ θ A ] ]
          ≡⟨ cong (λ φ → 𝔻 [ φ ∘ 𝔻 [ G.fmap f ∘ θ A ] ]) (sym (ηNat g)) ⟩
        𝔻 [ 𝔻 [ η C ∘ G.fmap g ] ∘ 𝔻 [ G.fmap f ∘ θ A ] ]
          ≡⟨ cong (λ φ → 𝔻 [ 𝔻 [ η C ∘ G.fmap g ] ∘ φ ]) (sym (θNat f)) ⟩
        𝔻 [ 𝔻 [ η C ∘ G.fmap g ] ∘ 𝔻 [ θ B ∘ F.fmap f ] ] ∎

  eval : Functor (CatProduct.object object ℂ) 𝔻
  eval = record
    { raw = record
      { omap = omap
      ; fmap = λ {dom} {cod} → fmap {dom} {cod}
      }
    ; isFunctor = record
      { isIdentity = λ {o} → ident {o}
      ; isDistributive = λ {f u n k y} → isDistributive {f} {u} {n} {k} {y}
      }
    }

  module _ (𝔸 : Category ℓ ℓ) (F : Functor (𝔸 ⊗ ℂ) 𝔻) where
    postulate
      parallelProduct
        : Functor 𝔸 object → Functor ℂ ℂ
        → Functor (𝔸 ⊗ ℂ) (object ⊗ ℂ)
      transpose : Functor 𝔸 object
      eq : F[ eval ∘ (parallelProduct transpose (identity {C = ℂ})) ] ≡ F
      -- eq : F[ :eval: ∘ {!!} ] ≡ F
      -- eq : Catℓ [ :eval: ∘ (HasProducts._|×|_ hasProducts transpose (𝟙 Catℓ {o = ℂ})) ] ≡ F
      -- eq' : (Catℓ [ :eval: ∘
      --   (record { product = product } HasProducts.|×| transpose)
      --   (𝟙 Catℓ)
      --   ])
      --   ≡ F

    -- For some reason after `e8215b2c051062c6301abc9b3f6ec67106259758`
    -- `catTranspose` makes Agda hang. catTranspose : ∃![ F~ ] (Catℓ [
    -- :eval: ∘ (parallelProduct F~ (𝟙 Catℓ {o = ℂ}))] ≡ F) catTranspose =
    -- transpose , eq

-- We don't care about filling out the holes below since they are anyways hidden
-- behind an unprovable statement.
module _ (ℓ : Level) (unprovable : IsCategory (RawCat ℓ ℓ)) where
  private
    Catℓ : Category (lsuc (ℓ ⊔ ℓ)) (ℓ ⊔ ℓ)
    Catℓ = Cat ℓ ℓ unprovable

    module _ (ℂ 𝔻 : Category ℓ ℓ) where
      module CatExp = CatExponential ℂ 𝔻
      _⊗_ = CatProduct.object

      -- Filling the hole causes Agda to loop indefinitely.
      eval : Functor (CatExp.object ⊗ ℂ) 𝔻
      eval = {!CatExp.eval!}

      isExponential : IsExponential Catℓ ℂ 𝔻 CatExp.object eval
      isExponential = {!CatExp.isExponential!}

      exponent : Exponential Catℓ ℂ 𝔻
      exponent = record
        { obj           = CatExp.object
        ; eval          = eval
        ; isExponential = isExponential
        }

  hasExponentials : HasExponentials Catℓ
  hasExponentials = record { exponent = exponent }
