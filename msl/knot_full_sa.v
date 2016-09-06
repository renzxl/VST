(*
 * Copyright (c) 2009-2011, Andrew Appel, Robert Dockins and Aquinas Hobor.
 *
 *)

Require Import msl.base.
Open Local Scope nat_scope.

Require Import msl.ageable.
Require Import msl.functors_variant.
Require Import msl.sepalg.
Require Import msl.xsepalg_functors.
Require Import msl.xsepalg_generators.
Require Import msl.age_sepalg.
Require Import msl.knot_full_variant.

Module Type KNOT_FULL_BASIC_INPUT.
  Parameter F: MixVariantFunctor.functor.
End KNOT_FULL_BASIC_INPUT.

Module Type KNOT_FULL_SA_INPUT.
  Declare Module KI: KNOT_FULL_BASIC_INPUT.
  Import MixVariantFunctor.
  Import KI.

  Parameter Join_F: forall A, Join (F A). Existing Instance Join_F.
  Parameter hom_F : forall {A B} (f: A -> B) (g: B -> A),
    join_hom (fmap F f g).
  Parameter Perm_F: forall A, Perm_alg (F A).
(*
  Parameter Sep_F: Sep_paf f_F Join_F.
  Parameter Canc_F: Canc_paf f_F Join_F.
  Parameter Disj_F: Disj_paf f_F Join_F.
*)
End KNOT_FULL_SA_INPUT.

Module Type KNOT_BASIC.
  Declare Module KI:KNOT_FULL_BASIC_INPUT.
  Import MixVariantFunctor.
  Import KI.
  Parameter knot: Type.
  Parameter ageable_knot : ageable knot.
  Existing Instance ageable_knot.

  Parameter predicate: Type.
  Parameter squash : (nat * F predicate) -> knot.
  Parameter unsquash : knot -> (nat * F predicate).
  Parameter approx : nat -> predicate -> predicate.

  Axiom squash_unsquash : forall k:knot, squash (unsquash k) = k.

  Axiom unsquash_squash : forall (n:nat) (f:F predicate),
    unsquash (squash (n,f)) = (n, fmap F (approx n) (approx n) f).

  Axiom knot_age1 : forall k:knot,
    age1 k = 
    match unsquash k with
    | (O,_) => None
    | (S n,x) => Some (squash (n,x))
    end.

  Axiom knot_level : forall k:knot,
    level k = fst (unsquash k).

End KNOT_BASIC.

Module Type KNOT_BASIC_LEMMAS.

  Declare Module K: KNOT_BASIC.
  Import MixVariantFunctor.
  Import K.KI.
  Import K.

  Axiom unsquash_inj : forall k1 k2,
    unsquash k1 = unsquash k2 ->
    k1 = k2.

  Axiom unsquash_approx : forall k n Fp,
    unsquash k = (n, Fp) ->
    Fp = fmap F (approx n) (approx n) Fp.
  Implicit Arguments unsquash_approx.

  Axiom approx_approx1 : forall m n,
    approx n = approx n oo approx (m+n).

  Axiom approx_approx2 : forall m n,
    approx n = approx (m+n) oo approx n.

End KNOT_BASIC_LEMMAS.

Module Type KNOT_FULL_SA.
  Declare Module KI: KNOT_FULL_BASIC_INPUT.
  Declare Module KSAI: KNOT_FULL_SA_INPUT with Module KI := KI.
  Declare Module K: KNOT_BASIC with Module KI := KI.
  Declare Module KL: KNOT_BASIC_LEMMAS with Module K := K.

  Import KI.
  Import KSAI.
  Import K.
  Import KL.

  Parameter Join_knot: Join knot.  Existing Instance Join_knot.
(*
  Parameter Perm_knot : Perm_alg knot.  Existing Instance Perm_knot.
  Parameter Sep_knot : (forall A, Sep_alg (F A)) -> Sep_alg knot.  Existing Instance Sep_knot.
  Parameter Canc_knot : (forall A, Canc_alg (F A)) -> Canc_alg knot.  Existing Instance Canc_knot.
  Parameter Disj_knot : (forall A, Disj_alg (F A)) -> Disj_alg knot.  Existing Instance Disj_knot.
*)
  Instance Join_nat_F: Join (nat * F predicate) := 
       Join_prod nat  (Join_equiv nat) (F predicate) _.

(*
  Instance Perm_nat_F : Perm_alg (nat * F predicate) :=
    @Perm_prod nat _ _ _ (Perm_equiv _) (Perm_F _).
  Instance Sep_nat_F (Sep_F: forall A, Sep_alg (F A)): Sep_alg (nat * F predicate) :=
    @Sep_prod nat _ _ _ (Sep_equiv _) (Sep_F predicate).
  Instance Canc_nat_F (Canc_F: forall A, Canc_alg (F A)): Canc_alg (nat * F predicate) :=
    @Canc_prod nat _ _ _ (Canc_equiv _) (Canc_F predicate).
  Instance Disj_nat_F (Disj_F: forall A, Disj_alg (F A)): Disj_alg (nat * F predicate) :=
    @Disj_prod nat _ _ _ (Disj_equiv _) (Disj_F predicate).
*)
  Axiom join_unsquash : forall x1 x2 x3 : knot,
    join x1 x2 x3 = join (unsquash x1) (unsquash x2) (unsquash x3).

  Axiom asa_knot : Age_alg knot.

End KNOT_FULL_SA.

Module KnotFullSa
  (KSAI': KNOT_FULL_SA_INPUT)
  (K': KNOT_BASIC with Module KI:=KSAI'.KI)
  (KL': KNOT_BASIC_LEMMAS with Module K:=K'):
  KNOT_FULL_SA with Module KI := KSAI'.KI
               with Module KSAI := KSAI'
               with Module K:=K'
               with Module KL := KL'.

  Module KI := KSAI'.KI.
  Module KSAI := KSAI'.
  Module K := K'.
  Module KL := KL'.

  Import MixVariantFunctor.
  Import MixVariantFunctorLemmas.
  Import KI.
  Import KSAI.
  Import K.
  Import KL.

  Instance Join_nat_F: Join (nat * F predicate) := 
       Join_prod nat  (Join_equiv nat) (F predicate) _.
  Instance Perm_nat_F : Perm_alg (nat * F predicate) :=
     @Perm_prod nat _ _ _ (Perm_equiv _) (Perm_F _).
(*
 Instance Sep_nat_F (Sep_F: forall A, Sep_alg (F A)): Sep_alg (nat * F predicate) :=
    @Sep_prod nat _ _ _ (Sep_equiv _) (Sep_F predicate).
 Instance Canc_nat_F (Canc_F: forall A, Canc_alg (F A)): Canc_alg (nat * F predicate) :=
    @Canc_prod nat _ _ _ (Canc_equiv _) (Canc_F predicate).
 Instance Disj_nat_F (Disj_F: forall A, Disj_alg (F A)): Disj_alg (nat * F predicate) :=
    @Disj_prod nat _ _ _ (Disj_equiv _) (Disj_F predicate).
*)
  Lemma unsquash_squash_join_hom : join_hom (unsquash oo squash).
  Proof.
    unfold compose.
    intros [x1 x2] [y1 y2] [z1 z2].
    split.
    + do 3 rewrite (unsquash_squash).
      firstorder.
      simpl in *.
      subst y1.
      subst z1.
      apply hom_F; auto.
    + intros.
      do 3 rewrite (unsquash_squash) in H.
      inv H.
      simpl in H0; inv H0; subst; constructor; auto.
      simpl in *.
      apply hom_F in H1; auto.
  Qed.

  Instance Join_knot : Join knot := 
           Join_preimage knot (nat * F predicate) Join_nat_F unsquash.

(*
  Instance Perm_knot : Perm_alg knot := 
    Perm_preimage _ _ _ _ unsquash squash squash_unsquash unsquash_squash_join_hom.

  Instance Sep_knot(Sep_F: forall A, Sep_alg (F A)) : Sep_alg knot := 
    Sep_preimage _ _ _  unsquash squash squash_unsquash unsquash_squash_join_hom.
*)
  Lemma join_unsquash : forall x1 x2 x3,
    join x1 x2 x3 =
    join (unsquash x1) (unsquash x2) (unsquash x3).
  Proof.
    intuition.
  Qed.
(*
  Instance Canc_knot(Canc_F: forall A, Canc_alg (F A)) : Canc_alg knot.
  Proof. repeat intro. 
            do 3 red in H, H0.
            apply unsquash_inj.
            apply (join_canc H H0).
  Qed.

  Instance Disj_knot(Disj_F: forall A, Disj_alg (F A)) : Disj_alg knot.
  Proof.
   repeat intro.
   do 3 red in H.
   apply join_self in H.
   apply unsquash_inj; auto.
  Qed.
*)
  Lemma age_join1 :
    forall x y z x' : K'.knot,
      join x y z ->
      age x x' ->
      exists y' : K'.knot,
        exists z' : K'.knot, join x' y' z' /\ age y y' /\ age z z'.
  Proof.
    intros.
    unfold age in *; simpl in *.
    rewrite knot_age1 in H0.
    repeat rewrite knot_age1.
    do 3 red in H.
    destruct (unsquash x) as [n f].
    destruct (unsquash y) as [n0 f0].
    destruct (unsquash z) as [n1 f1].
    destruct n; try discriminate.
    inv H0.
    simpl in H; destruct H.
    simpl in H; destruct H.
    subst n0 n1.
    exists (squash (n,f0)).
    exists (squash (n,f1)).
    simpl in H0.
    split; intuition. do 3  red.
    repeat rewrite unsquash_squash.
    split; auto. simpl snd.
    apply hom_F; auto.
  Qed.

  Lemma age_join2 :
    forall x y z z' : K'.knot,
      join x y z ->
      age z z' ->
      exists x' : K'.knot,
        exists y' : K'.knot, join x' y' z' /\ age x x' /\ age y y'.
  Proof.
    intros.
    unfold age in *; simpl in *.
    rewrite knot_age1 in H0.
    repeat rewrite knot_age1.
    do 3 red in H.
    destruct (unsquash x) as [n f].
    destruct (unsquash y) as [n0 f0].
    destruct (unsquash z) as [n1 f1].
    destruct n1; try discriminate.
    inv H0.
    destruct H; simpl in *.
    destruct H; subst.
    exists (squash (n1,f)).
    exists (squash (n1,f0)).
    split; intuition. do 3  red.
    repeat rewrite unsquash_squash.
    split; auto. simpl snd.
    apply hom_F; auto.
  Qed.

  Lemma unage_join1 : forall x x' y' z', join x' y' z' -> age x x' ->
    exists y, exists z, join x y z /\ age y y' /\ age z z'.
  Proof.
    intros.
    unfold join, Join_knot, Join_preimage, age in *; simpl in *.
    revert H0; rewrite knot_age1;
    destruct (unsquash x) as [n f] eqn:?H; intros.
    destruct n; inv H1.
    hnf in H. rewrite unsquash_squash in H. simpl in H.
    revert H.
    destruct (unsquash y') as [n0 f0] eqn:?H.
    destruct (unsquash z') as [n1 f1] eqn:?H; intros.
    destruct H2; simpl in *.
    destruct H2; subst.
    rename n1 into n.
    exists (squash (S n, f0)), (squash (S n, f1)).
    split; [| split].
    + rewrite !unsquash_squash.
      constructor.
      - constructor; auto.
      - simpl.
        rewrite (unsquash_approx H), (unsquash_approx H1) in H3.
        rewrite (approx_approx1 1 n) in H3 at 3 5.
        rewrite (approx_approx2 1 n) in H3 at 4 6.
        rewrite <- ff_comp in H3.
        unfold compose in H3; simpl in H3.
        apply (proj2 (hom_F _ _ _ _ _)) in H3; auto.
        apply functor_facts.
    + rewrite knot_age1.
      rewrite unsquash_squash. f_equal.
      replace y' with (squash (n,fmap F (approx (S n)) (approx (S n)) f0)); auto.
      apply unsquash_inj.
      rewrite unsquash_squash, H.
      apply injective_projections; simpl; auto.
      rewrite (unsquash_approx H).
      rewrite fmap_app.
      replace (S n) with (1 + n)%nat by trivial.
      rewrite <- (approx_approx1 1 n),  <- (approx_approx2 1 n).
      rewrite fmap_app.
      f_equal; symmetry; apply (approx_approx1 0 n).
    + rewrite knot_age1.
      rewrite unsquash_squash. f_equal.
      replace z' with  (squash (n, fmap F (approx (S n)) (approx (S n)) f1)); auto.
      apply unsquash_inj.
      rewrite unsquash_squash, H1.
      apply injective_projections; simpl; auto.
      rewrite (unsquash_approx H1).
      rewrite fmap_app.
      replace (S n) with (1 + n)%nat by trivial.
      rewrite <- (approx_approx1 1 n),  <- (approx_approx2 1 n).
      rewrite fmap_app.
      f_equal; symmetry; apply (approx_approx1 0 n).
  Qed.

  Lemma unage_join2 :
    forall z x' y' z', join x' y' z' -> age z z' ->
      exists x, exists y, join x y z /\ age x x' /\ age y y'.
  Proof.
    intros.
    rewrite join_unsquash in H. 
    revert H H0.
    unfold join, Join_knot, Join_preimage, age in *; simpl in *.
    repeat rewrite knot_age1.

    destruct (unsquash x') as [n f] eqn:?H;
    destruct (unsquash y') as [n0 f0] eqn:?H;
    destruct (unsquash z') as [n1 f1] eqn:?H;
    destruct (unsquash z) as [n2 f2] eqn:?H; intros.
    destruct n2;  inv H4.
    destruct H3. hnf in H3. simpl in *. destruct H3; subst.
    rewrite unsquash_squash in H1.
    inv H1.
    rename n1 into n.

    exists (squash (S n, f)).
    exists (squash (S n, f0)).
    split; [| split].

    + unfold join, Join_nat_F, Join_prod; simpl.
      repeat rewrite unsquash_squash.  simpl.  split; auto.

      rewrite (unsquash_approx H0), (unsquash_approx H) in H4.
      rewrite (approx_approx1 1 n) in H4 at 1 3.
      rewrite (approx_approx2 1 n) in H4 at 2 4.
      rewrite <- ff_comp in H4 by (apply functor_facts).
      apply paf_join_hom in H4; auto.
      constructor; intros; apply hom_F.
    + rewrite knot_age1; rewrite unsquash_squash; f_equal; hnf.
      apply unsquash_inj.
      rewrite unsquash_squash, H.
      apply injective_projections; simpl; auto.
      rewrite fmap_app.
      change (S n) with (1 + n).
      rewrite <- (approx_approx1 1 n).
      rewrite <- (approx_approx2 1 n).
      symmetry; eapply @unsquash_approx; eauto.
    + rewrite knot_age1; rewrite unsquash_squash; f_equal; hnf.
      apply unsquash_inj.
      rewrite unsquash_squash, H0.
      apply injective_projections; simpl; auto.
      rewrite fmap_app.
      change (S n) with (1 + n).
      rewrite <- (approx_approx1 1 n).
      rewrite <- (approx_approx2 1 n).
      symmetry; eapply @unsquash_approx; eauto.
  Qed.

  Theorem asa_knot : @Age_alg knot _ K.ageable_knot.
  Proof.
    constructor.
    exact age_join1.
    exact age_join2.
    exact unage_join1.
    exact unage_join2.
  Qed.

End KnotFullSa.
