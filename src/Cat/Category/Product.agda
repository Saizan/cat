{-# OPTIONS --allow-unsolved-metas --cubical #-}
module Cat.Category.Product where

open import Cubical.NType.Properties
open import Cat.Prelude hiding (_×_ ; proj₁ ; proj₂)
import Data.Product as P

open import Cat.Category

module _ {ℓa ℓb : Level} (ℂ : Category ℓa ℓb) where

  open Category ℂ

  module _ (A B : Object) where
    record RawProduct : Set (ℓa ⊔ ℓb) where
      no-eta-equality
      field
        object : Object
        proj₁  : ℂ [ object , A ]
        proj₂  : ℂ [ object , B ]

    -- FIXME Not sure this is actually a proposition - so this name is
    -- misleading.
    record IsProduct (raw : RawProduct) : Set (ℓa ⊔ ℓb) where
      open RawProduct raw public
      field
        ump : ∀ {X : Object} (f : ℂ [ X , A ]) (g : ℂ [ X , B ])
          → ∃![ f×g ] (ℂ [ proj₁ ∘ f×g ] ≡ f P.× ℂ [ proj₂ ∘ f×g ] ≡ g)

      -- | Arrow product
      _P[_×_] : ∀ {X} → (π₁ : ℂ [ X , A ]) (π₂ : ℂ [ X , B ])
        → ℂ [ X , object ]
      _P[_×_] π₁ π₂ = P.proj₁ (ump π₁ π₂)

    record Product : Set (ℓa ⊔ ℓb) where
      field
        raw        : RawProduct
        isProduct  : IsProduct raw

      open IsProduct isProduct public

  record HasProducts : Set (ℓa ⊔ ℓb) where
    field
      product : ∀ (A B : Object) → Product A B

    _×_ : Object → Object → Object
    A × B = Product.object (product A B)

    -- | Parallel product of arrows
    --
    -- The product mentioned in awodey in Def 6.1 is not the regular product of
    -- arrows. It's a "parallel" product
    module _ {A A' B B' : Object} where
      open Product
      open Product (product A B) hiding (_P[_×_]) renaming (proj₁ to fst ; proj₂ to snd)
      _|×|_ : ℂ [ A , A' ] → ℂ [ B , B' ] → ℂ [ A × B , A' × B' ]
      f |×| g = product A' B'
        P[ ℂ [ f ∘ fst ]
        ×  ℂ [ g ∘ snd ]
        ]

module _ {ℓa ℓb : Level} {ℂ : Category ℓa ℓb} {A B : Category.Object ℂ} where
  private
    open Category ℂ
    module _ (raw : RawProduct ℂ A B) where
      module _ (x y : IsProduct ℂ A B raw) where
        private
          module x = IsProduct x
          module y = IsProduct y

        module _ {X : Object} (f : ℂ [ X , A ]) (g : ℂ [ X , B ]) where
          prodAux : x.ump f g ≡ y.ump f g
          prodAux = {!!}

        propIsProduct' : x ≡ y
        propIsProduct' i = record { ump = λ f g → prodAux f g i }

      propIsProduct : isProp (IsProduct ℂ A B raw)
      propIsProduct = propIsProduct'

  Product≡ : {x y : Product ℂ A B} → (Product.raw x ≡ Product.raw y) → x ≡ y
  Product≡ {x} {y} p i = record { raw = p i ; isProduct = q i }
    where
    q : (λ i → IsProduct ℂ A B (p i)) [ Product.isProduct x ≡ Product.isProduct y ]
    q = lemPropF propIsProduct p

module _ {ℓa ℓb : Level} {ℂ : Category ℓa ℓb} {A B : Category.Object ℂ} where
  open Category ℂ
  private
    module _ (x y : HasProducts ℂ) where
      private
        module x = HasProducts x
        module y = HasProducts y
      module _ (A B : Object) where
        module pX = Product (x.product A B)
        module pY = Product (y.product A B)
        objEq : pX.object ≡ pY.object
        objEq = {!!}
        proj₁Eq : (λ i → ℂ [ objEq i , A ]) [ pX.proj₁ ≡ pY.proj₁ ]
        proj₁Eq = {!!}
        proj₂Eq : (λ i → ℂ [ objEq i , B ]) [ pX.proj₂ ≡ pY.proj₂ ]
        proj₂Eq = {!!}
        rawEq : pX.raw ≡ pY.raw
        RawProduct.object (rawEq i) = objEq i
        RawProduct.proj₁  (rawEq i) = {!!}
        RawProduct.proj₂  (rawEq i) = {!!}

        isEq : (λ i → IsProduct ℂ A B (rawEq i)) [ pX.isProduct ≡ pY.isProduct ]
        isEq = {!!}

        appEq : x.product A B ≡ y.product A B
        appEq = Product≡ rawEq

      productEq : x.product ≡ y.product
      productEq i = λ A B → appEq A B i

      propHasProducts' : x ≡ y
      propHasProducts' i = record { product = productEq i }

  propHasProducts : isProp (HasProducts ℂ)
  propHasProducts = propHasProducts'

module Try0 {ℓa ℓb : Level} {ℂ : Category ℓa ℓb}
  (let module ℂ = Category ℂ) {A B : ℂ.Object} (p : Product ℂ A B) where

  -- open Product p hiding (raw)
  open import Data.Product

  raw : RawCategory _ _
  raw = record
    { Object = Σ[ X ∈ ℂ.Object ] ℂ.Arrow X A × ℂ.Arrow X B
    ; Arrow = λ{ (X , xa , xb) (Y , ya , yb)
      → Σ[ xy ∈ ℂ.Arrow X Y ]
        ( ℂ [ ya ∘ xy ] ≡ xa)
        × ℂ [ yb ∘ xy ] ≡ xb
        }
    ; 𝟙 = λ{ {A , f , g} → ℂ.𝟙 {A} , ℂ.rightIdentity , ℂ.rightIdentity}
    ; _∘_ = λ { {A , a0 , a1} {B , b0 , b1} {C , c0 , c1} (f , f0 , f1) (g , g0 , g1)
      → (f ℂ.∘ g)
        , (begin
            ℂ [ c0 ∘ ℂ [ f ∘ g ] ] ≡⟨ ℂ.isAssociative ⟩
            ℂ [ ℂ [ c0 ∘ f ] ∘ g ] ≡⟨ cong (λ φ → ℂ [ φ ∘ g ]) f0 ⟩
            ℂ [ b0 ∘ g ] ≡⟨ g0 ⟩
            a0 ∎
          )
        , (begin
           ℂ [ c1 ∘ ℂ [ f ∘ g ] ] ≡⟨ ℂ.isAssociative ⟩
           ℂ [ ℂ [ c1 ∘ f ] ∘ g ] ≡⟨ cong (λ φ → ℂ [ φ ∘ g ]) f1 ⟩
           ℂ [ b1 ∘ g ] ≡⟨ g1 ⟩
            a1 ∎
          )
      }
    }

  open RawCategory raw

  isAssocitaive : IsAssociative
  isAssocitaive {A , a0 , a1} {B , _} {C , c0 , c1} {D , d0 , d1} {ff@(f , f0 , f1)} {gg@(g , g0 , g1)} {hh@(h , h0 , h1)} i
    = s0 i , rl i , rr i
    where
    l = hh ∘ (gg ∘ ff)
    r = hh ∘ gg ∘ ff
    -- s0 : h ℂ.∘ (g ℂ.∘ f) ≡ h ℂ.∘ g ℂ.∘ f
    s0 : proj₁ l ≡ proj₁ r
    s0 = ℂ.isAssociative {f = f} {g} {h}
    prop0 : ∀ a → isProp (ℂ [ d0 ∘ a ] ≡ a0)
    prop0 a = ℂ.arrowsAreSets (ℂ [ d0 ∘ a ]) a0
    rl : (λ i → (ℂ [ d0 ∘ s0 i ]) ≡ a0) [ proj₁ (proj₂ l) ≡ proj₁ (proj₂ r) ]
    rl = lemPropF prop0 s0
    prop1 : ∀ a → isProp ((ℂ [ d1 ∘ a ]) ≡ a1)
    prop1 a = ℂ.arrowsAreSets _ _
    rr : (λ i → (ℂ [ d1 ∘ s0 i ]) ≡ a1) [ proj₂ (proj₂ l) ≡ proj₂ (proj₂ r) ]
    rr = lemPropF prop1 s0

  isIdentity : IsIdentity 𝟙
  isIdentity {AA@(A , a0 , a1)} {BB@(B , b0 , b1)} {f , f0 , f1} = leftIdentity , rightIdentity
    where
    leftIdentity : 𝟙 ∘ (f , f0 , f1) ≡ (f , f0 , f1)
    leftIdentity i = l i , rl i , rr i
      where
      L = 𝟙 ∘ (f , f0 , f1)
      R : Arrow AA BB
      R = f , f0 , f1
      l : proj₁ L ≡ proj₁ R
      l = ℂ.leftIdentity
      prop0 : ∀ a → isProp ((ℂ [ b0 ∘ a ]) ≡ a0)
      prop0 a = ℂ.arrowsAreSets _ _
      rl : (λ i → (ℂ [ b0 ∘ l i ]) ≡ a0) [ proj₁ (proj₂ L) ≡ proj₁ (proj₂ R) ]
      rl = lemPropF prop0 l
      prop1 : ∀ a → isProp (ℂ [ b1 ∘ a ] ≡ a1)
      prop1 _ = ℂ.arrowsAreSets _ _
      rr : (λ i → (ℂ [ b1 ∘ l i ]) ≡ a1) [ proj₂ (proj₂ L) ≡ proj₂ (proj₂ R) ]
      rr = lemPropF prop1 l
    rightIdentity : (f , f0 , f1) ∘ 𝟙 ≡ (f , f0 , f1)
    rightIdentity i = l i , rl i , {!!}
      where
      L = (f , f0 , f1) ∘ 𝟙
      R : Arrow AA BB
      R = (f , f0 , f1)
      l : ℂ [ f ∘ ℂ.𝟙 ] ≡ f
      l = ℂ.rightIdentity
      prop0 : ∀ a → isProp ((ℂ [ b0 ∘ a ]) ≡ a0)
      prop0 _ = ℂ.arrowsAreSets _ _
      rl : (λ i → (ℂ [ b0 ∘ l i ]) ≡ a0) [ proj₁ (proj₂ L) ≡ proj₁ (proj₂ R) ]
      rl = lemPropF prop0 l
      prop1 : ∀ a → isProp ((ℂ [ b1 ∘ a ]) ≡ a1)
      prop1 _ = ℂ.arrowsAreSets _ _
      rr : (λ i → (ℂ [ b1 ∘ l i ]) ≡ a1) [ proj₂ (proj₂ L) ≡ proj₂ (proj₂ R) ]
      rr = lemPropF prop1 l

  cat : IsCategory raw
  cat = record
    { isAssociative = isAssocitaive
    ; isIdentity    = isIdentity
    ; arrowsAreSets = {!!}
    ; univalent     = {!!}
    }

  module cat = IsCategory cat

  lemma :  Terminal ≃ Product ℂ A B
  lemma = {!!}

  thm : isProp (Product ℂ A B)
  thm = equivPreservesNType {n = ⟨-1⟩} lemma cat.Propositionality.propTerminal

--   open Univalence ℂ.isIdentity
--   open import Cat.Equivalence hiding (_≅_)

--   k : {A B : ℂ.Object} → isEquiv (A ≡ B) (A ℂ.≅ B) (ℂ.id-to-iso A B)
--   k = ℂ.univalent

--   module _ {X' Y' : Σ[ X ∈ ℂ.Object ] (ℂ [ X , A ] × ℂ [ X , B ])} where
--     open Σ X' renaming (proj₁ to X) using ()
--     open Σ (proj₂ X') renaming (proj₁ to Xxa ; proj₂ to Xxb)
--     open Σ Y' renaming (proj₁ to Y) using ()
--     open Σ (proj₂ Y') renaming (proj₁ to Yxa ; proj₂ to Yxb)
--     module _ (p : X ≡ Y) where
--       D : ∀ y → X ≡ y → Set _
--       D y q = ∀ b → (λ i → ℂ [ q i , A ]) [ Xxa ≡ b ]
--       -- Not sure this is actually provable - but if it were it might involve
--       -- something like the ump of the product -- in which case perhaps the
--       -- objects of the category I'm constructing should not merely be the
--       -- data-part of the product but also the laws.

--       -- d : D X refl
--       d : ∀ b → (λ i → ℂ [ X , A ]) [ Xxa ≡ b ]
--       d b = {!!}
--       kk : D Y p
--       kk = pathJ D d Y p
--       a : (λ i → ℂ [ p i , A ]) [ Xxa ≡ Yxa ]
--       a = kk Yxa
--       b : (λ i → ℂ [ p i , B ]) [ Xxb ≡ Yxb ]
--       b = {!!}
--       f : X' ≡ Y'
--       f i = p i , a i , b i

--     module _ (p : X' ≡ Y') where
--       g : X ≡ Y
--       g i = proj₁ (p i)

--     step0 : (X' ≡ Y') ≃ (X ≡ Y)
--     step0 = Equiv≃.fromIsomorphism _ _ (g , f , record { verso-recto = {!refl!} ; recto-verso = refl})

--     step1 : (X ≡ Y) ≃ X ℂ.≅ Y
--     step1 = ℂ.univalent≃

--     -- Just a reminder
--     step1-5 : (X' ≅ Y') ≡ (X ℂ.≅ Y)
--     step1-5 = refl

--     step2 : (X' ≡ Y') ≃ (X ℂ.≅ Y)
--     step2 = Equivalence.compose step0 step1

--     univalent : isEquiv (X' ≡ Y') (X ℂ.≅ Y) (id-to-iso X' Y')
--     univalent = proj₂ step2

--   isCategory : IsCategory raw
--   isCategory = record
--     { isAssociative = ℂ.isAssociative
--     ; isIdentity = ℂ.isIdentity
--     ; arrowsAreSets = ℂ.arrowsAreSets
--     ; univalent = univalent
--     }

--   category : Category _ _
--   category = record
--     { raw = raw
--     ; isCategory = isCategory
--     }

--   open Category category hiding (IsTerminal ; Object)

--   -- Essential turns `p : Product ℂ A B` into a triple
--   productObject : Object
--   productObject = Product.object p , Product.proj₁ p , Product.proj₂ p

--   productObjectIsTerminal : IsTerminal productObject
--   productObjectIsTerminal = {!!}

--   proppp : isProp (IsTerminal productObject)
--   proppp = Propositionality.propIsTerminal productObject

-- module Try1 {ℓa ℓb : Level} (A B : Set) where
--   open import Data.Product
--   raw : RawCategory _ _
--   raw = record
--     { Object = Σ[ X ∈ Set ] (X → A) × (X → B)
--     ; Arrow = λ{ (X0 , f0 , g0) (X1 , f1 , g1) → X0 → X1}
--     ; 𝟙 = λ x → x
--     ; _∘_ = λ x x₁ x₂ → x (x₁ x₂)
--     }

--   open RawCategory raw

--   isCategory : IsCategory raw
--   isCategory = record
--     { isAssociative = refl
--     ; isIdentity = refl , refl
--     ; arrowsAreSets = {!!}
--     ; univalent = {!!}
--     }

--   t : IsTerminal ((A × B) , proj₁ , proj₂)
--   t = {!!}
