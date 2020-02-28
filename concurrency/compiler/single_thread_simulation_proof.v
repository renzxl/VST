Require Import Omega.

Require Import Coq.Classes.Morphisms.
Require Import Relation_Definitions.

Require Import compcert.common.Globalenvs.
Require Import compcert.common.ExposedSimulations.
Require Import compcert.common.Values.
Require Import compcert.common.Memory.
Require Import compcert.lib.Coqlib.

Require Import VST.concurrency.lib.tactics.
Require Import VST.concurrency.common.Compcert_lemmas.
Require Import VST.concurrency.common.permissions. Import permissions.
Require Import VST.concurrency.common.semantics. 
Require Import VST.concurrency.compiler.concurrent_compiler_simulation.
Require Import VST.concurrency.compiler.sequential_compiler_correct.
Require Import VST.concurrency.compiler.advanced_permissions.
Require Import VST.concurrency.compiler.CoreSemantics_sum.
Require Import VST.concurrency.common.HybridMachine.
Require Import VST.concurrency.compiler.HybridMachine_simulation.
Require Import VST.concurrency.compiler.Asm_lemmas.
Require Import VST.concurrency.compiler.synchronisation_symulations.



Require Import VST.concurrency.lib.Coqlib3.

Require Import VST.concurrency.memsem_lemmas.
Import BinNums.

Import BinInt.
Import List.
Import Integers.
Import Ptrofs.
Import Basics.
Import FunctionalExtensionality.

Require Import VST.concurrency.compiler.Clight_self_simulation.
Require Import VST.concurrency.compiler.Asm_self_simulation.
Require Import VST.concurrency.compiler.diagrams.
Require Import VST.concurrency.common.mem_equiv.
Require Import VST.concurrency.lib.pair.
Require Import VST.concurrency.compiler.inject_virtue.
Require Import VST.concurrency.compiler.concur_match.
Require Import VST.concurrency.lib.Coqlib3.
 

Set Nested Proofs Allowed.
Set Bullet Behavior "Strict Subproofs".

(*Clight Machine *)
Require Import VST.concurrency.common.ClightMachine.
(*Asm Machine*)
Require Import VST.concurrency.common.x86_context.
Require Import VST.concurrency.compiler.concurrent_compiler_simulation_definitions.
Import bounded_maps.


(* migration: MOVE TO OTHER FILES: *)

      (* Propers for Clight and Asm *)

(* End MIGRATION! *)


Ltac subst_sig:=
  match goal with
    H': existT _ _ _ = existT _ _ _ |- _ =>
    eapply Eqdep.EqdepTheory.inj_pair2 in H'; subst
  end.




Section ThreadedSimulation.
  Context {CC_correct: CompCert_correctness}
          {Args: ThreadSimulationArguments}.
  
  Import HybridMachineSig.
  Import DryHybridMachine.
  Import self_simulation.
  
  (*Module MySyncSimulation:= SyncSimulation CC_correct Args.
  Import MySyncSimulation.*)
  
  Existing Instance OrdinalPool.OrdinalThreadPool.
  Existing Instance HybridMachineSig.HybridCoarseMachine.DilMem.
  (* Module MyConcurMatch := ConcurMatch CC_correct Args.*)

  

  
  Section ThreadedSimulation.
    (*Import MySimulationTactics.MyConcurMatch.*)
    
    
    
    Section CompileOneThread.
      Import OrdinalPool.
      Context (hb: nat).
      (*Instantiate definitions in Concur with the current hybridbound*)
      Notation concur_match:= (concur_match hb).
      Notation match_thread:= (match_thread hb).
      Notation match_thread_source:= (match_thread_source hb).
      Notation match_thread_target:= (match_thread_target hb).
      
      Notation memcompat2:= (memcompat2 hb).
      Notation memcompat1:= (memcompat1 hb).
      Notation contains12:= (contains12 hb).
      Notation mtch_target:= (mtch_target hb).
      Notation mtch_compiled:= (mtch_compiled hb).
      Notation mtch_source:= (mtch_source hb).
      Notation thread_perms st i cnt:= (fst (@getThreadR _ _ st i cnt)).
      Notation lock_perms st i cnt:= (snd (@getThreadR  _ _ st i cnt)).
      
      Existing Instance HybridSem.
      Existing Instance dryResources.
      Existing Instance DryHybridMachineSig.
      

      Definition cast_t {Sem}:
        @OrdinalPool.t _ Sem -> @ThreadPool.t _ Sem (@OrdinalThreadPool dryResources _):=
        fun X => X.

      Lemma free_perms:
        forall m b0 lo hi m', Mem.free m b0 lo hi = Some m' ->
                         forall b ofs,
                           (getCurPerm m') !! b ofs =
                           (getCurPerm m) !! b ofs /\
                           (getMaxPerm m') !! b ofs =
                           (getMaxPerm m) !! b ofs
                           \/
                           (getCurPerm m) !! b ofs = Some Freeable.
      Proof.
        intros.
        repeat rewrite getCurPerm_correct, getMaxPerm_correct.
        unfold permission_at.
        pose proof (juicy_mem.free_not_freeable_eq m b0 lo hi m' b ofs H).
        unfold Memory.access_at in *; simpl in *.
        eapply Mem.free_result in H as HH.
        unfold Mem.unchecked_free in H; subst m'; simpl in *.
        clear H0.
        destruct (peq b b0); subst.
        - rewrite PMap.gss. 
          match_case; eauto.
          right. eapply Mem.free_range_perm in H. 
          exploit (H ofs).
          + eapply andb_prop in Heqb; normal_hyp.
            simpl in *.
            destruct (zle lo ofs); simpl in *; try congruence.
            destruct (zlt ofs hi); simpl in *; try congruence.
            omega.
          + unfold Mem.perm.
            destruct ((Mem.mem_access m) !! b0 ofs Cur);
              intros HH; inv HH; eauto.
        - rewrite PMap.gso; auto.
      Qed.
      Lemma mem_step_perms_max:
        forall m m', mem_step m m' ->
                forall b ofs,
                  (getCurPerm m') !! b ofs = (getCurPerm m) !! b ofs /\
                  (getMaxPerm m') !! b ofs = (getMaxPerm m) !! b ofs \/
                  (getMaxPerm m) !! b ofs = None \/
                  (getCurPerm m) !! b ofs = Some Freeable.
      Proof.
        intros. induction H.
        - left. split; symmetry;
                  try eapply memory_lemmas.MemoryLemmas.mem_storebytes_cur; eauto.
          do 2 erewrite getMaxPerm_correct; unfold permission_at.
          symmetry; erewrite Mem.storebytes_access; eauto.
        - destruct (peq b b').
          + subst; right; left.
            apply Mem.alloc_result in H.
            pose proof (Mem.nextblock_noaccess m b' ofs Max).
            rewrite_getPerm; apply H0.
            subst; apply Plt_strict.
          + left. 
            pose proof (Memory.alloc_access_other m lo hi m' b' H b ofs).
            pose proof (H0 Cur ltac:(left; eauto)).
            pose proof (H0 Max ltac:(left; eauto)).
            unfold Memory.access_at in *. repeat rewrite_getPerm.
            simpl in *; eauto.
        - revert  m m' H b ofs.
          induction l.
          + simpl; intros. inv H; eauto.
          + intros. simpl in H.
            destruct a as (p0, hi); destruct p0 as (b0, lo).
            match_case in H.
            exploit free_perms; eauto. intros HH.
            destruct HH as [ [HH1 HH2] |]; eauto.
            repeat rewrite <- HH1; rewrite <- HH2.
            clear HH1 HH2.
            eapply IHl; eauto.
        - destruct IHmem_step1 as [[HH1 HH2]|[?|?]]; eauto.
          repeat rewrite <- HH1, <- HH2; eauto.
      Qed.
      
      Lemma mem_step_perms:
        forall m m', mem_step m m' ->
                forall b ofs,
                  (getCurPerm m') !! b ofs = (getCurPerm m) !! b ofs \/
                  (getMaxPerm m) !! b ofs = None \/
                  (getCurPerm m) !! b ofs = Some Freeable.
      Proof.
        intros; exploit mem_step_perms_max; eauto;
          intros [[]|[?|?]]; eauto.
      Qed.
      
      Lemma perms_permMapsDisjoint:
        forall A A' M B,
          (forall b ofs, A' !! b ofs = A !! b ofs \/
                    M !! b ofs = None \/
                    A !! b ofs = Some Freeable) ->
          permMapLt B M ->
          permMapsDisjoint A B ->
          permMapsDisjoint A'  B.
      Proof.
        intros * HH Hlt Hdisj b ofs.
        specialize (HH b ofs).
        destruct HH as [?|[? | ?]].
        - rewrite H; eapply Hdisj.
        - specialize (Hlt b ofs).
          rewrite H in Hlt; simpl in Hlt.
          match_case in Hlt.
          unfold perm_union. econstructor; simpl.
          match_case; eauto.
        - specialize (Hdisj b ofs);
            destruct Hdisj. rewrite H in H0.
          simpl in H0. match_case in H0.
          unfold perm_union. econstructor; simpl.
          match_case; eauto.
      Qed.
      
      Lemma perms_permMapCoherence:
        forall A A' M B,
          (forall b ofs, A' !! b ofs = A !! b ofs \/
                    M !! b ofs = None \/
                    A !! b ofs = Some Freeable) ->
          permMapLt B M ->
          permMapCoherence A B ->
          permMapCoherence A'  B.
      Proof.
        intros * HH Hlt Hdisj b ofs.
        specialize (HH b ofs).
        destruct HH as [?|[? | ?]].
        - rewrite H; eapply Hdisj.
        - specialize (Hlt b ofs).
          rewrite H in Hlt; simpl in Hlt.
          match_case in Hlt.
          unfold perm_coh. 
          repeat match_case; eauto.
        - specialize (Hdisj b ofs); hnf in Hdisj.
          rewrite H in Hdisj; match_case in Hdisj.
          unfold perm_coh. repeat match_case; eauto.
      Qed.
      Instance permMapCoherence_Proper:
        Proper (access_map_equiv ==> access_map_equiv ==> iff) permMapCoherence.
      Proof.
        setoid_help.proper_iff; setoid_help.proper_intros.
        intros b ofs; unfold permMapCoherence in *.
        rewrite <- H, <- H0. apply H1.
      Qed.
      
      Lemma mem_step_preserves_invariant:
        forall hb (st st': @t dryResources (HybridSem (@Some nat hb)))
          i cnt m m' c
          (Hcur: access_map_equiv (getCurPerm m) (thread_perms i st cnt)),
          @mem_compatible (HybridSem _) _ st m ->
          @invariant  (HybridSem _) _ st ->
          mem_step m m' ->
          st' = updThread cnt c (getCurPerm m', snd (@getThreadR dryResources _ i st cnt)) ->
          @invariant (HybridSem _) _ st'.
      Proof.
        intros.
        rename H into Hcmpt.
        rename H0 into Hinv.

        pose proof (mem_step_perms _ _ H1) as Hperms; clear H1.
        
        eapply synchronisation_lemmas.invariant_update_thread; simpl; eauto.
        - intros. assert (Hneq: i <> j) by eauto; clear H.
          unshelve exploit @no_race_thr; try eapply Hneq; simpl; eauto.
          intros [? ?]; split; simpl in *; eauto.
          
          eapply perms_permMapsDisjoint; eauto.
          + eapply Hcmpt.
          + eapply permMapsDisjoint_Proper; try eapply Hcur; try eassumption; try reflexivity.
            
        - intros. 
          unshelve exploit @no_race; simpl; eauto.
          intros [? ?]; split; simpl in *; eauto.
          
          eapply perms_permMapsDisjoint; eauto.
          + eapply Hcmpt; eauto.
          + eapply permMapsDisjoint_Proper; try eapply Hcur; try eassumption; reflexivity.
        - simpl. eapply perms_permMapCoherence; eauto.
          + eapply Hcmpt; eauto.
          + rewrite Hcur. exploit @thread_data_lock_coh; eauto.
            intros [? ?]. eapply H.
        - simpl; intros.
          split.
          + exploit @thread_data_lock_coh; eauto. intros [? _].
            eapply perms_permMapCoherence; eauto.
            * eapply Hcmpt; eauto.
            * rewrite Hcur. exploit @thread_data_lock_coh; eauto.
              intros [? ?]. simpl in *. eapply H1.
          + exploit @thread_data_lock_coh; eauto. intros [? _].
            simpl in *; eapply H0.
        - simpl; intros. split.
    + eapply Hinv; eauto.
    + exploit @locks_data_lock_coh; eauto. intros [? _].
      eapply perms_permMapCoherence; eauto.
      * eapply Hcmpt; eauto.
      * rewrite Hcur. apply H0.

        Unshelve.
        all: simpl; eauto.
      Qed.

        
    Lemma Asm_preserves_invariant:
  forall hb g i (st: @t dryResources (HybridSem (@Some nat hb)))
    cnt st' (th_st: Smallstep.state (Asm.part_semantics g)) c2 m Hlt t0
    (Hgenv:Asm_core.safe_genv Asm_g),
    @mem_compatible (HybridSem _) _ st m ->
    @invariant  (HybridSem _) _ st ->
    let th_perm:= @getThreadR _ _ i st cnt in
    let th_m:= @restrPermMap (fst th_perm) m Hlt in
    forall (Hext:Asm.at_external Asm_g (Asm.set_mem c2 th_m) = None),
    Asm.step Asm_g (Asm.set_mem c2 th_m) t0 th_st ->
    st' = updThread cnt (Krun (TST th_st))
                    (getCurPerm (Smallstep.get_mem th_st),
                     snd (getThreadR cnt)) ->
    @invariant (HybridSem _) _ st'.
Proof.
  intros.
  rename H into Hcmpt.
  rename H0 into Hinv.

  eapply (mem_step_preserves_invariant _ _ _ _ _ th_m); eauto.
  - subst_set. eapply getCur_restr.
  - subst_set; eapply synchronisation_lemmas.compat_restr; eauto.
  - exploit Asm_core.asm_mem_step.
    + simpl; econstructor; simpl; eauto. 
    + assumption. 
    + auto.
Qed.
Lemma Clight_preserves_invariant:
  forall hb g i (st: @t dryResources (HybridSem (@Some nat hb)))
    cnt st' (th_st: Smallstep.state (Clight.part_semantics2 g)) c2 m Hlt t0,
    @mem_compatible (HybridSem _) _ st m ->
    @invariant  (HybridSem _) _ st ->
    let th_perm:= @getThreadR _ _ i st cnt in
    let th_m:= @restrPermMap (fst th_perm) m Hlt in
    forall (Hext:Clight.at_external (Clight.set_mem c2 th_m) = None),
    Clight.step2 g (Clight.set_mem c2 th_m) t0 th_st ->
    st' = updThread cnt (Krun (SST th_st))
                    (getCurPerm (Smallstep.get_mem th_st),
                     snd (getThreadR cnt)) ->
    @invariant (HybridSem _) _ st'.
Proof.
  intros.
  rename H into Hcmpt.
  rename H0 into Hinv.

  eapply (mem_step_preserves_invariant _ _ _ _ _ th_m); eauto.
  - subst_set. eapply getCur_restr.
  - subst_set; eapply synchronisation_lemmas.compat_restr; eauto.
  - eapply Clightcore_coop.CLC_corestep_mem; simpl.
    econstructor; eauto.
Qed.

Definition cmpt_valid_blocks (Sem : Semantics) (tpool : ThreadPool.ThreadPool)
       (tp : ThreadPool.t) (m : mem):=
  forall (l : address) (rmap : lock_info),
                     ThreadPool.lockRes tp l = Some rmap ->
                     Mem.valid_block m (fst l).
Record factored_compt(Sem : Semantics) (tpool : ThreadPool.ThreadPool)
       (tp : ThreadPool.t) (m : mem) b ofs : Prop :=
  { compat_th : forall (tid : nat) (cnt : ThreadPool.containsThread tp tid),
      Mem.perm_order'' ((getMaxPerm m)!! b ofs)
                       ((fst (ThreadPool.getThreadR cnt)) !! b ofs)  /\
      Mem.perm_order'' ((getMaxPerm m)!! b ofs)
                       ((snd (ThreadPool.getThreadR cnt)) !! b ofs);
    compat_lp : forall (l : address) (pmaps : lock_info),
        ThreadPool.lockRes tp l = Some pmaps ->
        Mem.perm_order'' ((getMaxPerm m)!! b ofs)
                         ((fst pmaps) !! b ofs)  /\
        Mem.perm_order'' ((getMaxPerm m)!! b ofs)
                         ((snd pmaps) !! b ofs)}.


Lemma factor_compt:
  forall Sem tpool tp m,
    (@mem_compatible Sem tpool tp m) <->
    (cmpt_valid_blocks Sem tpool tp m /\
      forall b ofs, @factored_compt Sem tpool tp m b ofs).
Proof.
  intros; split; intros * HH.
  - inv HH; econstructor; intros; eauto.
    econstructor; intros; eauto.
    + split; eapply compat_th0.
    + split; eapply compat_lp0; eauto.
  - econstructor; intros; eauto.
    + split; intros ??; eapply HH.
    + split; intros ??; eapply HH; eauto.
    + eapply HH; eauto. 
Qed.
Lemma useful_disjoint:
  forall A B X b ofs,
    permMapsDisjoint A B ->
    B !! b ofs = Some Freeable ->
    Mem.perm_order'' X (A !! b ofs).
Proof.
  intros.
  specialize (H b ofs); rewrite H0 in H.
  inv H. unfold perm_union in H1; repeat match_case in H1.
  apply event_semantics.po_None.
Qed.
Lemma useful_coherence:
  forall A B X b ofs,
    permMapCoherence B A ->
    B !! b ofs = Some Freeable ->
    Mem.perm_order'' X (A !! b ofs).
Proof.
  intros.
  specialize (H b ofs); rewrite H0 in H.
  simpl in H. repeat match_case in H.
  apply event_semantics.po_None.
Qed.
Lemma mem_step_preserves_compat:
  forall hb i (st: @t dryResources (HybridSem (@Some nat hb)))
    cnt st' m m' c
    (Hcur: access_map_equiv (getCurPerm m) (thread_perms i st cnt)),
    @invariant (HybridSem _) _ st -> 
    @mem_compatible (HybridSem _) _ st m ->
    mem_step m m' ->
    st' = updThread cnt c
                    (getCurPerm m',
                     snd (getThreadR cnt)) ->
      @mem_compatible (HybridSem _) _ st' m'.
Proof.
    intros.
    rename H0 into Hcmpt.
    rename H into Hinv.
    pose proof (mem_step_perms_max _ _ H1) as Hperms.

    eapply factor_compt in Hcmpt as [Hlock_valid Hcmpt].
  
    eapply factor_compt; split.
    {!goal(cmpt_valid_blocks _ _ _ _ ).
     eapply mem_step_nextblock' in H1.
     hnf; intros. unfold Mem.valid_block.
     
     subst st'; simpl in *; rewrite gsoThreadLPool in H.
     eapply Hlock_valid in H; eauto. unfold Mem.valid_block in H.
     eapply Plt_Ple_trans; try eassumption. }

    
    intros b ofs. specialize (Hcmpt b ofs).
    
  specialize (Hperms b ofs);
    destruct Hperms as [?|[?|?]]; normal_hyp; swap 1 2.
    -  inv Hcmpt. rewrite H in *.
     econstructor.
     + intros tid cnt'.
       destruct (Nat.eq_dec i tid).
       * subst; unshelve exploit @gssThreadRes; try eapply cnt'.
         simpl; intros HH; rewrite HH; simpl.
         split.
         -- simpl. eapply cur_lt_max.
         -- simpl; eapply perm_order''_trans; eauto.
            apply event_semantics.po_None.
            eapply compat_th0.
       * assert (cnt0:containsThread st tid) by eauto.
         exploit (gsoThreadRes cnt0 n cnt'); simpl;
           intros HH; rewrite HH; clear HH.
         split; simpl; eapply perm_order''_trans; eauto;
         try eapply event_semantics.po_None;
         eapply compat_th0.
     + simpl. intros. rewrite gsoThreadLPool in H0.
         split; simpl; eapply perm_order''_trans; eauto;
         try eapply event_semantics.po_None;
         eapply compat_lp0; eauto.
  - inv Hcmpt. rewrite <- H0 in *. 
    econstructor.
    + intros tid cnt'.
       destruct (Nat.eq_dec i tid).
       * subst; unshelve exploit @gssThreadRes; try eapply cnt'.
         simpl; intros HH; rewrite HH; simpl.
         split.
         -- simpl. eapply cur_lt_max.
         -- eapply compat_th0.
      * assert (cnt0:containsThread st tid) by eauto.
         exploit (gsoThreadRes cnt0 n cnt'); simpl;
           intros HH; rewrite HH; clear HH.
         eapply compat_th0.
    + simpl. intros. rewrite gsoThreadLPool in H2.
      eapply compat_lp0; eauto.
  - econstructor.
    + intros tid cnt'.
       rewrite Hcur in H.
       destruct (Nat.eq_dec i tid).
       * subst; unshelve exploit @gssThreadRes; try eapply cnt'.
         simpl; intros HH; rewrite HH; simpl.
         split.
         -- simpl. eapply cur_lt_max.
         -- eapply useful_coherence; eauto.
            inv Hinv.
            specialize (thread_data_lock_coh0 _ cnt) as (? & _).
            eapply H0.
       * subst st'; assert (cnt0:containsThread st tid).
         { simpl in cnt'. eapply cntUpdate'; eauto . }
         exploit (gsoThreadRes cnt0 n cnt'); simpl;
           intros HH; rewrite HH; clear HH.
         split; [eapply useful_disjoint| eapply useful_coherence]; try eassumption.
         -- apply permMapsDisjoint_comm.
            eapply Hinv; auto.
         -- inv Hinv; simpl in *.
            specialize (thread_data_lock_coh0 _ cnt0) as (? & _).
            eapply H0.
    + rewrite Hcur in H.
      subst; simpl. intros. rewrite gsoThreadLPool in H0.
      split; [eapply useful_disjoint| eapply useful_coherence]; try eassumption.
      * apply permMapsDisjoint_comm.
        inv Hinv. eapply no_race0; eauto.
      * inv Hinv; simpl in *.
        specialize (locks_data_lock_coh0 _ _ H0) as (? & _).
        eapply H2.
  Qed.

  Lemma Asm_preserves_compat:
  forall hb g i (st: @t dryResources (HybridSem (@Some nat hb)))
    cnt st' (th_st: Smallstep.state (Asm.part_semantics g)) c2 m Hlt t0
    (Hgenv:Asm_core.safe_genv Asm_g),
    @invariant (HybridSem _) _ st -> 
    @mem_compatible (HybridSem _) _ st m ->
    let th_perm:= @getThreadR _ _ i st cnt in
    let th_m:= @restrPermMap (fst th_perm) m Hlt in
    forall (Hext:Asm.at_external Asm_g (Asm.set_mem c2 th_m) = None),
    Asm.step Asm_g (Asm.set_mem c2 th_m) t0 th_st ->
    st' = updThread cnt (Krun (TST th_st))
                    (getCurPerm (Smallstep.get_mem th_st),
                     snd (getThreadR cnt)) ->
    @mem_compatible (HybridSem _) _ st' (Asm.get_mem th_st).
  Proof.
  
  intros.
  rename H into Hinv.
  rename H0 into Hcmpt.
  simpl in H1.
  exploit Asm_core.asm_mem_step.
  { simpl; econstructor; simpl; eauto. }
  { assumption. }
  intros HH.

  eapply mem_step_preserves_compat; try eapply HH; eauto.
  - subst_set. apply getCur_restr.
  - subst_set; apply mem_compat_restrPermMap; assumption.
  Qed.

    Lemma Asm_plus_preserves_invariant_cmpt:
  forall hb g i (st: @t dryResources (HybridSem (@Some nat hb)))
    cnt st' (th_st: Smallstep.state (Asm.part_semantics g)) c2 m Hlt
    (Hgenv:Asm_core.safe_genv Asm_g),
    @mem_compatible (HybridSem _) _ st m ->
    @invariant  (HybridSem _) _ st ->
    let th_perm:= @getThreadR _ _ i st cnt in
    let th_m:= @restrPermMap (fst th_perm) m Hlt in
    corestep_plus (Asm_core.Asm_core_sem Asm_g) c2 
                  th_m th_st (Smallstep.get_mem th_st) ->
    st' = updThread cnt (Krun (TST th_st))
                    (getCurPerm (Smallstep.get_mem th_st),
                     snd (getThreadR cnt)) ->
    @invariant (HybridSem _) _ st' /\
    @mem_compatible (HybridSem _) _ st' (Smallstep.get_mem th_st).
Proof.
  intros.
  rename H into Hcmpt.
  rename H0 into Hinv.

  destruct H1.  revert st th_st m Hcmpt Hinv cnt Hlt th_perm th_m c2 st' H2 H .
  induction x.
  - intros. simpl in H. destruct H as (?&?&?&HH); inv HH.
    inv H; simpl in *. split.
    + eapply Asm_preserves_invariant; eauto.
    + eapply Asm_preserves_compat; eauto.
  - intros. simpl in H. destruct H as (?&?&H&Hsteps).
    inv H; simpl in *.
    eapply Asm_preserves_invariant in H0 as Hinv'; eauto.
    eapply Asm_preserves_compat in H0 as Hcmpt'; eauto.
    eapply IHx; eauto.
    + rewrite updThread_twice, gssThreadRes; auto.
    + erewrite restrPermMap_rewrite, <- mem_is_restr_eq; eauto.
      rewrite gssThreadRes; reflexivity.

      Unshelve.
      all: eauto.
      rewrite gssThreadRes; simpl.
      apply cur_lt_max.
Qed.


  
  Lemma Clight_preserves_compat:
    
  forall hb g i (st: @t dryResources (HybridSem (@Some nat hb)))
    cnt st' (th_st: Smallstep.state (Clight.part_semantics2 g)) c2 m Hlt t0,
    @mem_compatible (HybridSem _) _ st m ->
    @invariant  (HybridSem _) _ st ->
    let th_perm:= @getThreadR _ _ i st cnt in
    let th_m:= @restrPermMap (fst th_perm) m Hlt in
    forall (Hext:Clight.at_external (Clight.set_mem c2 th_m) = None),
    Clight.step2 g (Clight.set_mem c2 th_m) t0 th_st ->
    st' = updThread cnt (Krun (SST th_st))
                    (getCurPerm (Smallstep.get_mem th_st),
                     snd (getThreadR cnt)) ->
    @mem_compatible (HybridSem _) _ st' (Clight.get_mem th_st).
  Proof.
  
  intros.
  rename H into Hinv.
  rename H0 into Hcmpt.
  simpl in H1.
  exploit Clightcore_coop.CLC_corestep_mem; simpl.
  { simpl; econstructor; simpl; eauto. }
  intros HH.

  eapply mem_step_preserves_compat; try eapply HH; eauto.
  - subst_set. apply getCur_restr.
  - subst_set; apply mem_compat_restrPermMap; assumption.
  Qed.

Inductive sync_event: Events.event -> Prop:=
| sync_Event_acq_rel: forall e dmp e',
    sync_event (Events.Event_acq_rel e dmp e')
| sync_Event_spawn: forall b dmp1 dmp2,
    sync_event (Events.Event_spawn b dmp1 dmp2).
Definition not_sync_event (ev:Events.event):= ~ sync_event ev.
Definition not_sync_trace := Forall not_sync_event.


Definition Asm_externals_have_events {F V} (ge:Genv.t (AST.fundef F) V):=
  forall b f ef args res m t m',
    Genv.find_funct_ptr ge b = Some (AST.External f) ->
    Events.external_call ef Asm_g args m t res m' ->
    t <> nil.
Context (Hexterns_have_events: Asm_externals_have_events Asm_g)
        (Hrestricted_builtins: Asm_core.safe_genv Asm_g).

  Lemma step_nil_trace_not_atx:
  forall s1 s2,
    Asm.step Asm_g s1 nil s2 ->
    Asm.at_external Asm_g s1 = None.
Proof.
  intros. unfold Asm.at_external.
  inv H.
  - rewrite H0.
    match_case. rewrite H1; auto.
  - rewrite H0.
    match_case. rewrite H1; auto.
  - rewrite H0.
    match_case. rewrite H1; auto.
    eapply Asm.get_arguments_correct in H2.
    rewrite H2.
    eapply Hexterns_have_events in H3; eauto.
    congruence.
Qed.

      (* Where to move this:*)
      
      (*
        ConcurMatch used to be here. 
       *)

      
      (* The following tactics are also in permissions.v  
         but for some reason that one doesn't work...
       *)
      Ltac unfold_getCurPerm:=
        repeat rewrite getCurPerm_correct in *;
        unfold permission_at in *.
      Ltac unfold_getMaxPerm:=
        repeat rewrite getMaxPerm_correct in *;
        unfold permission_at in *.
      Ltac unfold_getPerm:=
        try unfold_getMaxPerm; try unfold_getMaxPerm.
      
      (** *Tactics
         These tactics are here becasue they must be outside a section.
         they also must be after concur_match definition.
       *)

      (*Do I have to reppeat the LTAC from the section? *)


      Inductive opt_rel' {A} (ord: A -> A -> Prop): option A -> option A -> Prop:=
      | Some_ord:
          forall x y, ord x y -> opt_rel' ord (Some x) (Some y).
      
      Lemma option_wf:
        forall A (ord: A -> A -> Prop),
          well_founded ord ->
          well_founded (opt_rel' ord).
      Proof.
        unfold well_founded.
        intros.
        destruct a.
        2: econstructor; intros; inversion H0.
        specialize (H a).
        induction H.
        econstructor; intros.
        inversion H1; subst.
        eapply H0; eauto.
      Qed.


      Lemma simulation_equivlanence:
        forall s3 t s2 cd cd0,
          (Smallstep.plus (Asm.step (Genv.globalenv Asm_program)) 
                          s3 t s2 \/
           Smallstep.star (Asm.step (Genv.globalenv Asm_program)) 
                          s3 t s2 /\ InjorderX compiler_sim cd cd0) ->
          Smallstep.plus (Asm.step (Genv.globalenv Asm_program)) 
                         s3 t s2 \/
          t = Events.E0 /\
          s2 = s3 /\
          InjorderX compiler_sim cd cd0.
      Proof.
        intros. destruct H; eauto.
        destruct H.
        inversion H; subst; eauto.
        left. econstructor; eauto.
      Qed.
      


      (*This lemma is used when the compiled thread steps*)
      
      Ltac exploit_match tac:=  
        unfold match_thread_target,match_thread_source in *;
        repeat match goal with
               | [ H: ThreadPool.getThreadC ?i = _ ?c |- _] => simpl in H
               end;
        match goal with
        | [ H: getThreadC ?i = _ ?c,
               H0: context[match_thread] |- _ ] =>
          match type of H0 with
          | forall (_: ?Hlt1Type) (_: ?Hlt2Type), _ =>
            assert (Hlt1:Hlt1Type); [
              first [eassumption | tac | idtac]|
              assert (Hlt2:Hlt2Type); [
                first [eassumption | tac | idtac]|
                specialize (H0 Hlt1 Hlt2);
                rewrite H in H0; inversion H0; subst; simpl in *; clear H0
            ]]
          end

        | [ H: getThreadC ?i = _ ?c,
               H0: context[match_thread_compiled] |- _ ] =>
          match type of H0 with
          | forall (_: ?Hlt1Type) (_: ?Hlt2Type), _ =>
            assert (Hlt1:Hlt1Type); [
              first [eassumption | tac | idtac]|
              assert (Hlt2:Hlt2Type); [
                first [eassumption | tac | idtac]|
                specialize (H0 Hlt1 Hlt2);
                rewrite H in H0; inversion H0; subst; simpl in *; clear H0
            ]]
          end
        end;
        fold match_thread_target in *;
        fold match_thread_source in *.

      (* Build the concur_match *)
      Ltac destroy_ev_step_sum:=
        match goal with
        | [ H: ev_step_sum _ _ _ _ _ _ _ |- _ ] => inversion H; clear H
        end.
      
      Lemma break_existensial_of_thread_stepN:
        forall G TID SCH TR C M res, 
        forall Sem ge U c1 m1 c2 m2 c3 m3,
        @machine_semantics.thread_step G TID SCH TR C M res Sem ge U c1 m1 c2 m2 ->
        (exists n : nat, machine_semantics_lemmas.thread_stepN Sem ge n U c2 m2 c3 m3) ->
        exists n : nat, machine_semantics_lemmas.thread_stepN Sem ge (S n) U c1 m1 c3 m3.
      Proof.
        intros; normal.
        repeat (econstructor; eauto).
      Qed.
      
      Lemma thread_step_plus_from_corestep':
        forall NN m tge U i st2 m2
          (Hinv: @invariant (HybridSem _) (@OrdinalThreadPool dryResources _) st2)
          (code2 : Asm.state)
          (s4' : Smallstep.state (Asm.part_semantics Asm_g))
          (cnt2: containsThread st2 i)
          (Hcmpt: mem_compatible st2 m2)
          (m4' : mem) m2_i Hlt2
          (Hm_eq: m2_i =  (@restrPermMap (fst (getThreadR cnt2)) m2 Hlt2)),
          corestepN (Asm_core.Asm_core_sem Asm_g) (S NN) code2 m2_i s4' m4' ->
          getThreadC cnt2 = Krun (TST code2) ->
            HybridMachineSig.schedPeek U = Some i ->
            machine_semantics_lemmas.thread_step_plus
              (HybConcSem (Some (S hb)) m) tge U st2
              m2 (updThread cnt2 (Krun (TState Clight.state Asm.state s4'))
                            (getCurPerm m4', snd (getThreadR cnt2))) m4'.
      Proof.
        simpl; induction NN; intros.
        - subst; destruct H as (c2 & m3 & STEP & Heq). inv Heq.
          simpl in STEP. inv STEP.
          exists O; simpl; do 2 eexists. split; try reflexivity.
          dilute_mem (Asm.get_mem s4').
          exploit Asm_event.asm_ev_ax2.
          econstructor; simpl in *; eassumption.
          intros (T&HH).
          econstructor; try eassumption; simpl.
          do 2 (econstructor; eauto); try reflexivity.
          + clean_proofs; eauto.
            
        - simpl in H; normal.
          simpl in H. inv H; simpl in *.
          eapply break_existensial_of_thread_stepN.
          + (* first step *)
            dilute_mem (Asm.get_mem s4').
            exploit Asm_event.asm_ev_ax2.
            { econstructor; simpl in *; eassumption. }
            intros (T&HH).
            do 2 (econstructor; eauto); try reflexivity.
            * constructor;clean_proofs; eauto.
          + (* The rest of the steps (inductively) *)
            match goal with
              |- exists x, machine_semantics_lemmas.thread_stepN _ _ _ _ ?upd_st2
                                                           _ _ _ =>
              remember upd_st2 as st2'
            end.
            assert (cnt2': containsThread st2' i).
            { subst. eapply cntUpdate; auto. }
            assert (HH:(thread_perms i st2' cnt2') = (getCurPerm (Asm.get_mem x))).
            { subst st2'; pose proof (@gssThreadRR dryResources _ i st2).
              simpl in *; rewrite H; auto. }
            assert (Hinv':invariant st2').
            { eapply Asm_preserves_invariant; eauto. }
            exploit IHNN.
            * apply Hinv'.
            * eapply Asm_preserves_compat; try eapply Hcmpt; eauto.
            * pose proof (mem_is_restr_eq (Asm.get_mem x)).
              clean_proofs.
              remember (getCurPerm (Asm.get_mem x))  as TEMP.
              rewrite <- HH in HeqTEMP; subst TEMP.
              erewrite restr_proof_irr.
              eapply H.
              
            * normal; [apply H2 | apply H3]. 
            * subst st2'.
              pose proof @gssThreadCC.
              specialize (H dryResources _ i st2 cnt2
                            (Krun (TState (@semC CSem) (@semC AsmSem) x)) cnt2').
              simpl in *; apply H.
            * eassumption.
            (* * erewrite (mem_is_restr_eq (Asm.get_mem x)).
              clean_proofs.
              remember ( getCurPerm (Asm.get_mem x))  as TEMP.
              rewrite <- HH in HeqTEMP; subst TEMP.
              unshelve (apply restr_proof_irr). *)
      
            * intros (n&c3&m3&one_step&many_steps).
            eexists (S n); simpl.
            exists c3, m3. split.
            -- eassumption.
            -- simpl in *.
              instantiate(1:= tge) in many_steps.
              instantiate(1:= m) in many_steps.
              match goal with
                [H: machine_semantics_lemmas.thread_stepN _ _ _ _ _ _ ?S _
                 |- machine_semantics_lemmas.thread_stepN _ _ _ _ _ _ ?S' _ ]=>
                replace S' with S; eauto
              end.
              subst st2'.
              rewrite updThread_twice.
              do 2 f_equal.
              unfold lock_perms.
              pose proof (@gssThreadRR dryResources _ i st2).
              simpl in *.
              rewrite H; reflexivity.

              Unshelve.
              apply Asm_genv_safe.
              assumption.
              apply Asm_genv_safe.
              assumption.

              { eapply tge. }
              { eapply tge. }
              { assert (HH:(thread_perms i st2' cnt2') = (getCurPerm (Asm.get_mem x))).
                { subst st2'; pose proof (@gssThreadRR dryResources _ i st2).
                  simpl in *; rewrite H; auto. }
                rewrite HH.
                eapply mem_cur_lt_max. }
      Qed.
              
      Lemma thread_step_plus_from_corestep:
        forall (m : option mem) (tge : ClightSemanticsForMachines.G * Asm.genv)
          i
          (U : list nat) (st1 : t) (m1 : mem) (Htid : containsThread st1 i) 
          (st2 : t) (mu : meminj) (m2 : mem) (cd0 : compiler_index)
          (CMatch : concur_match (Some cd0) mu st1 m1 st2 m2) (code2 : Asm.state)
          (s4' : Smallstep.state (Asm.part_semantics Asm_g)) 
          (m4' : mem) (cnt2 : containsThread st2 i),
          getThreadC cnt2 = Krun (TST code2) ->
          HybridMachineSig.schedPeek U = Some i ->
          corestep_plus (Asm_core.Asm_core_sem Asm_g) code2
                        (restrPermMap
                           (proj1 ((memcompat2 CMatch) i (contains12 CMatch Htid))))
                        s4' m4' ->
            machine_semantics_lemmas.thread_step_plus
              (HybConcSem (Some (S hb)) m) tge U st2
              m2 (updThread cnt2 (Krun (TState Clight.state Asm.state s4'))
                            (getCurPerm m4', snd (getThreadR cnt2))) m4'.
      Proof.
        (** NOTE: This might be missing that the corestep never reaches an at_external
                  If this is the case, we might need to thread that through the compiler...
                  although it should be easy, I would prefere if there is any other way...
         *)
        intros * HgetC Hschedule H.
        destruct H as (NN& H).
        clean_proofs.
        eapply thread_step_plus_from_corestep'; eauto; try apply CMatch.
      Qed.

      

      
          Lemma nil_eapp:
            forall t1 t2,
            Events.Eapp t1 t2 = nil ->
            t1 = nil /\ t2 = nil.
          Proof.
            intros t1 t2; destruct t1; destruct t2; simpl; intros;
              eauto; congruence. 
          Qed.
          
          (** *Need an extra fact about simulations*)
          Lemma step2corestep_star:
            forall (s1 s2: Smallstep.state (Asm.part_semantics Asm_g)),
              Smallstep.star
            (Asm.step (Genv.globalenv Asm_program))
            s1 nil s2 ->
              (corestep_star (Asm_core.Asm_core_sem Asm_g))
                s1 (Smallstep.get_mem s1) s2 (Smallstep.get_mem s2).
          Proof.
            intros * H. eapply Smallstep.star_starN in H as [n H].
            exists n.
            revert s1 s2 H. induction n.
            - intros. simpl; intros; inv H. 
              reflexivity.
            - intros; inv H.
              symmetry in H3; eapply nil_eapp in H3 as [? ?];subst.
              exploit IHn; eauto; intros Hsteps.
              do 2 eexists; split.
              + econstructor; eauto; simpl.
                rewrite asm_set_mem_get_mem; eauto.
                rewrite asm_set_mem_get_mem;
                  eapply step_nil_trace_not_atx; eauto.
              + eauto.
          Qed.
      Lemma step2corestep_plus:
        forall (s1 s2: Smallstep.state (Asm.part_semantics Asm_g)) m1,
          Smallstep.plus
            (Asm.step (Genv.globalenv Asm_program))
            (Smallstep.set_mem s1 m1) nil s2 ->
          (corestep_plus (Asm_core.Asm_core_sem Asm_g))
            s1 m1 s2 (Smallstep.get_mem s2).
      Proof.
        intros; inv H.
        symmetry in H2; eapply nil_eapp in H2 as [? ?]; subst.
        eapply corestep_plus_star_trans.
        - exists 0%nat; simpl.
          do 2 eexists; split; try reflexivity.
          econstructor; eauto.
          + eapply step_nil_trace_not_atx; eauto.
        - apply step2corestep_star in H1. simpl.
          destruct s3; eassumption.
      Qed.
          
      (* This in principle is not provable. We should get it somehow from the simulation.
              Possibly, by showing that the (internal) Clight step has no traces and allo
              external function calls have traces, so the "matching" Asm execution must be
              all internal steps (because otherwise the traces wouldn't match).
       *)
      
      
      Lemma Clight_step_nil_trace_not_atx:
        forall s1 s2 f t,
          Clight.at_external s1 = None ->
          Clight.step Clight_g f s1 t s2 ->
          t = nil.
      Proof.
      Admitted.
      (* When a thread takes an internal step (i.e. not changing the schedule) *)
      Lemma asm_get_mem_set_mem:
        forall s m, Asm.get_mem (Asm.set_mem s m) = m.
      Proof. intros st; destruct st; reflexivity. Qed.
      Lemma Clight_set_mem_get_mem
        : forall s, Clight.set_mem s (Clight.get_mem s) = s.
      Proof. intros st; destruct st; reflexivity. Qed.
      
      Lemma internal_step_diagram:
        forall (m : option mem) (sge tge : HybridMachineSig.G) (U : list nat) tr1
          (st1 : ThreadPool (Some hb)) m1 (st1' : ThreadPool (Some hb)) m1',
          machine_semantics.thread_step (HybConcSem (Some hb) m) sge U st1 m1 st1' m1' ->
          forall cd tr2 (st2 : ThreadPool (Some (S hb))) mu m2,
            concur_match cd mu st1 m1 st2 m2 ->
            forall (Hmatch_event : List.Forall2 (inject_mevent mu) tr1 tr2),
            exists (st2' : ThreadPool (Some (S hb))) m2' cd' mu',
              concur_match cd' mu' st1' m1' st2' m2' /\
              List.Forall2 (inject_mevent mu') tr1 tr2 /\
              (machine_semantics_lemmas.thread_step_plus
                 (HybConcSem (Some (S hb)) m) tge U st2 m2 st2' m2' \/
               machine_semantics_lemmas.thread_step_star
                 (HybConcSem (Some (S hb)) m) tge U st2 m2 st2' m2' /\
               opt_rel' (InjorderX compiler_sim) cd' cd) /\
      inject_incr mu mu'.
      Proof.
        intros.
        inversion H; subst.
        inversion Htstep; subst.
        destruct (Compare_dec.lt_eq_lt_dec tid hb) as [[?|?]|?].  
        - (* tid < hb *)
          pose proof (mtch_target _ _ _ _ _ _ H0 _ l Htid (contains12 H0 Htid)) as HH.
          simpl in *.

          exploit_match ltac:(apply H0).
          destroy_ev_step_sum; subst; simpl in *; simpl.
          eapply Asm_event.asm_ev_ax1 in H2.
          instantiate (1:=Asm_genv_safe) in H2.
          
          eapply Aself_simulation in H5; eauto.
          destruct H5 as (c2' & f' & t' & m2' &
                          (CoreStep & MATCH & Hincr & is_ext & inj_trace)).
          

          eapply Asm_event.asm_ev_ax2 in CoreStep; try eapply Asm_genv_safe.
          destruct CoreStep as (?&?); eauto.
          
          (* contains.*)
          pose proof (@contains12  H0 _ Htid) as Htid'.

          (* Construct the new thread pool *)
          exists (updThread Htid' (Krun (TState Clight.state Asm.state c2'))
                       (getCurPerm m2', snd (getThreadR Htid'))).
          (* new memory is given by the self_simulation. *)
          exists m2', cd, f'.
          repeat weak_split.
          + (*Reestablish the concur_match *)
            simpl.
            move H0 at bottom.
            dup H0 as Hcmpt2.
            eapply memcompat2 in Hcmpt2.
            
            eapply concur_match_update1; eauto.
            { eapply semantics.corestep_mem in H2. eapply H2. }
            { instantiate(1:=Hcmpt2).
              eapply Asm_event.asm_ev_ax1 in H1.
              eapply semantics.corestep_mem.
              instantiate(1:=c2').
              instantiate(1:=code2).
              repeat abstract_proofs; unify_proofs; eauto.
            }
            
            { apply H0. }

            (*The compiler match*)
            econstructor 2; eauto.
            simpl in MATCH.
            unfold match_thread_target; simpl.
            constructor.
            exact MATCH.
            
          + (* Reestablish inject_mevent *)
            eapply inject_incr_trace; eauto.
          + left. (* Construct the step *)
            exists 0%nat; simpl.
            do 2 eexists; split; [|reflexivity].
            dilute_mem m2'.
            econstructor; eauto; simpl.
            econstructor; eauto.
            * simpl in *.
              eapply H0.
            * simpl; erewrite restr_proof_irr; econstructor; eauto.
            * simpl; repeat (f_equal; try eapply Axioms.proof_irr).
          + assumption.
          + erewrite restr_proof_irr; eassumption.
            
            
        - (*  tid = hb*)
          pose proof (mtch_compiled _ _ _ _ _ _ H0 _ e Htid (contains12 H0 Htid)) as HH.
          subst.
          simpl in *.
          
          exploit_match ltac:(apply H0).

          
          (* This takes three steps:
           1. Simulation of the Clight semantics  
           2. Simulation of the compiler (Clight and Asm) 
           3. Simulation of the Asm semantics 
           *)
          
          rename H6 into Compiler_Match; simpl in *.
          
          (* (1) Clight step *)
          destroy_ev_step_sum. subst m'0 t0 s.
          eapply (event_semantics.ev_step_ax1 (@semSem CSem)) in H2; eauto.
          
          (* (2) Compiler step/s *)
          rename H2 into CoreStep.
          simpl in CoreStep.
          inversion CoreStep. subst s1 m0 s2.
          
          eapply compiler_sim in H1 as HH; simpl in *; eauto.
          2: { erewrite restr_proof_irr; eassumption. }
          destruct HH as (cd' & s2' & j2' & t'' & step &
                          comp_match & Hincr2 & inj_event).
          assert (Ht0: t0 = nil).
          { eapply Clight_step_nil_trace_not_atx; eauto. } subst t0.
          assert (Ht'': t'' = nil).
          { inv inj_event; reflexivity. } subst t''.
          eapply simulation_equivlanence in step.
          assert ( HH: Asm.state =
                       Smallstep.state (Asm.part_semantics Asm_g)) by
              reflexivity.
          remember (@Smallstep.get_mem (Asm.part_semantics Asm_g) s2') as m2'.
          pose proof (contains12 H0 Htid) as Htid'.
          
          (*Invariant + compatible of the new source state (st1'): *)
          exploit Clight_preserves_invariant; eauto;
            intros Hinv1'.
          eapply Clight_preserves_compat in Hcmpt as Hcmpt1'; eauto.

          destruct step as [plus_step | (? & ? & ?)].
          +
            (*assert (@invariant
                      _ (TP (Some _))
                      (updThread Htid (Krun (SState Clight.state Asm.state s'))
                                 (getCurPerm (Clight.get_mem s'), lock_perms hb st1 Htid))).
            { *)

            
            exists (updThread Htid' (Krun (TState Clight.state Asm.state s2'))
                         (getCurPerm m2', snd (getThreadR Htid'))), m2', (Some cd'), j2'.
            repeat weak_split.
            * (*assert (CMatch := H0). inversion H0;*)
              rename H0 into CMatch.
              subst. simpl. intros.
              Lemma concur_match_thread_step:
                forall (st2 : ThreadPool.t) (st1 st1': ThreadPool.t) (m1 m1' m2 m2' : mem) (tid : nat)
                  (Htid1 : ThreadPool.containsThread st1 tid)
                  c1 (cd cd' : option compiler_index) (st2' : ThreadPool.t) 
                  (mu mu' : meminj)
                  c2 (Htid2 : ThreadPool.containsThread st2 tid),
                  concur_match cd mu st1 m1 st2 m2 ->
                  individual_match hb tid cd' mu' c1 m1' c2 m2' ->
                  Mem.inject mu' m1' m2' ->
                  inject_incr mu mu' ->
                  Events.injection_full mu' m1' ->
                  @invariant (HybridSem (Some hb)) _ st1' ->
                  @invariant (HybridSem (Some (S hb))) _ st2' ->
                  mem_compatible st1' m1' ->
                  mem_compatible st2' m2' -> 
                  Events.injection_full mu' m1' ->
                  forall p2,
                    (* we do this to cover the case where st2' = st2*)
                    access_map_equiv (getCurPerm m2') p2 ->  
                  st1' = (updThread Htid1 c1
                                    (getCurPerm m1', (snd (getThreadR Htid1)))) ->
                  st2' = (updThread Htid2 c2
                               (p2, (snd (getThreadR Htid2)))) ->
                  concur_match cd' mu' st1' m1' st2' m2'.
              Proof.
                (* Need to use the invariants and memcompat1-compat to
                   reestablish the injections.
                 *)
              Admitted.
              eapply (concur_match_thread_step st2 st1);
                try reflexivity; eauto; try now eapply compiler_sim; eauto.
              -- econstructor 3; auto. constructor; eauto.
                 unfold compiler_match.
                 simpl. rewrite asm_set_mem_get_mem,  Clight_set_mem_get_mem.
                 eauto.
              -- unshelve eapply Asm_plus_preserves_invariant_cmpt; try reflexivity;
                 try (eapply memcompat2; apply CMatch); shelve_unifiable; eauto.
                 apply CMatch.
                 clean_proofs_goal; simpl; match_case.
                 apply step2corestep_plus; simpl; eauto. revert plus_step.
                 clean_proofs_goal; simpl; eauto.
                 
              -- unshelve eapply Asm_plus_preserves_invariant_cmpt; try reflexivity;
                 try (eapply memcompat2; apply CMatch); shelve_unifiable; eauto.
                 eapply CMatch.
                 clean_proofs_goal; simpl; match_case.
                 apply step2corestep_plus; simpl; eauto. revert plus_step.
                 clean_proofs_goal; simpl; eauto.
                 
                 
            * eapply inject_incr_trace; try eassumption.
            * left.
              eapply thread_step_plus_from_corestep; eauto.
              -- symmetry; revert H4; clean_proofs_goal; eauto.
              -- subst m2'.
                 instantiate(1:=Htid).
                 instantiate (5:=H0).
                 erewrite restr_proof_irr; eauto.
                 instantiate(1:=Hlt2).
                 eapply step2corestep_plus; simpl in *. 
                 eauto.
            * assumption.
                 
          + exists st2, m2, (Some cd'), j2'.
            repeat weak_split.
            * (* assert (CMatch := H0). inversion H0;*)
              rename H0 into CMatch.
              pose proof (updThread_same Htid') as Hst2_eq.
              symmetry in Hst2_eq.
              replace (getThreadR Htid') with
                  (thread_perms _ _ Htid', lock_perms _ _ Htid') in Hst2_eq.
              2:{ destruct (getThreadR Htid'); reflexivity. }
              subst.
              eapply concur_match_perm_restrict'.
              rewrite <- mem_is_restr_eq.
              instantiate(1:= Hlt2).
              erewrite <- (asm_get_mem_set_mem _ (restrPermMap Hlt2)).
              eapply concur_match_thread_step;try eapply Hst2_eq;
                try reflexivity;
                       eauto; try now eapply compiler_sim; eauto.
              -- revert H4; clean_proofs_goal; intros <-.
                econstructor 3; auto. constructor; eauto.
                 unfold compiler_match.
                 simpl. rewrite Clight_set_mem_get_mem, asm_get_mem_set_mem.
                 eauto.
              -- apply CMatch.
              -- rewrite asm_get_mem_set_mem.
                 apply mem_compat_restrPermMap, CMatch.
              -- rewrite asm_get_mem_set_mem.
                 clean_proofs_goal; apply getCur_restr.
            * eapply inject_incr_trace; try eassumption.
            * right; split.
              { (*zero steps*)
                exists 0%nat; simpl; auto. }
              { (*order of the index*)
                constructor; auto.  }
            * assumption.
        - (* tid > hb *)
          pose proof (mtch_source _ _ _ _ _ _ H0 _ l Htid (contains12 H0 Htid)) as HH.
          simpl in *.
          exploit_match ltac:(apply H0).
          destroy_ev_step_sum; subst; simpl in *.
          simpl.
          eapply (event_semantics.ev_step_ax1 (@semSem CSem)) in H2; eauto.
          replace Hcmpt with (memcompat1 H0) in H2
            by eapply Axioms.proof_irr.
          
          eapply Cself_simulation in H5; eauto.
          destruct H5 as (c2' & f' & t' & m2' & (CoreStep & MATCH & Hincr & His_ext & Htrace)).
          
          eapply (event_semantics.ev_step_ax2 (@semSem CSem)) in CoreStep.
          destruct CoreStep as (?&?); eauto.
          
          (* contains.*)
          pose proof (contains12 H0 Htid) as Htid'.

          (* Construct the new thread pool *)
          exists (updThread Htid' (Krun (SState Clight.state Asm.state c2'))
                       (getCurPerm m2', snd (getThreadR Htid'))).
          (* new memory is given by the self_simulation. *)
          exists m2', cd, f'. repeat weak_split.
          
          + (*Reestablish the concur_match *)
            simpl.
            move H0 at bottom.
            eapply concur_match_update1; eauto.
            { eapply semantics.corestep_mem in H2.
              eapply H2. }
            { eapply (event_semantics.ev_step_ax1 (@semSem CSem)) in H1.
              eapply semantics.corestep_mem in H1.
              clean_proofs.
              erewrite restr_proof_irr.
              eassumption.
            }
            { apply H0. }
            
            econstructor 1; eauto.
            simpl in MATCH.
            unfold match_thread_source; simpl.
            constructor.
            exact MATCH.
          + eapply inject_incr_trace; try eassumption. 
          + (* Construct the step *)
            left; exists 0%nat; simpl.
            do 2 eexists; split; [|reflexivity].
            dilute_mem m2'.
            econstructor; eauto; simpl.
            econstructor; eauto.
            * simpl in *.
              eapply H0.
            * simpl. 
              erewrite restr_proof_irr.
              econstructor; eauto.
            * simpl; repeat (f_equal; try eapply Axioms.proof_irr).
          + assumption.
          + erewrite restr_proof_irr.
            eassumption.


            Unshelve. all: auto.
            (*This shouldn't be her e*) 
            all: try (exact nil).
            all: try (eapply H0).
            { !goal (Asm.genv).
              eapply  (Asm.part_semantics Asm_g). }
            { !goal (Asm.genv).
              eapply  (Asm.part_semantics Asm_g). }
      Qed.

      (** *Diagrams for machine steps*)
      
      
      (* What to do with this? *)
      Hint Resolve inject_incr_refl: core.

      Lemma start_step_diagram:
        forall (m : option mem) (tge : HybridMachineSig.G) 
               (U : list nat) (st1 : ThreadPool (Some hb)) 
               (m1 : mem) (tr1 tr2 : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some hb)) (m' : mem)
               (cd : option compiler_index) (st2 : ThreadPool (Some (S hb)))
               (mu : meminj) (m2 : mem) (tid : nat)
               (Htid : ThreadPool.containsThread st1 tid),
          concur_match cd mu st1 m1 st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          HybridMachineSig.schedPeek U = Some tid ->
          HybridMachineSig.start_thread m1 Htid st1' m' ->
          exists
            (st2' : ThreadPool (Some (S hb))) (m2' : mem) 
            (cd' : option compiler_index) (mu' : meminj),
            concur_match cd' mu' st1' (HybridMachineSig.diluteMem m') st2'
                         m2' /\
            List.Forall2 (inject_mevent mu') tr1 tr2 /\
            machine_semantics.machine_step(HybConcSem (Some (S hb)) m) tge
                                          U tr2 st2 m2
                                          (HybridMachineSig.yield
                                             (Scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
                                             U) tr2 st2' m2'
      /\ inject_incr mu mu'.
      Proof.
        intros.
        inv H2.
        
        
        
      Admitted.
      
      Lemma resume_step_diagram:
        forall (m : option mem) (tge : HybridMachineSig.G) 
               (U : list nat) (st1 : ThreadPool (Some hb))
               (tr1 tr2 : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some hb)) (m1' : mem)
               (cd : option compiler_index) (st2 : ThreadPool (Some (S hb)))
               (mu : meminj) (m2 : mem) (tid : nat)
               (Htid : ThreadPool.containsThread st1 tid),
          concur_match cd mu st1 m1' st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          HybridMachineSig.schedPeek U = Some tid ->
          HybridMachineSig.resume_thread m1' Htid st1' ->
          exists
            (st2' : ThreadPool (Some (S hb))) (m2' : mem) 
            (cd' : option compiler_index) (mu' : meminj),
            concur_match cd' mu' st1' m1' st2' m2' /\
            List.Forall2 (inject_mevent mu') tr1 tr2 /\
            machine_semantics.machine_step
              (HybConcSem (Some (S hb)) m) tge
              U tr2 st2 m2
              (HybridMachineSig.yield
                 (Scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
                 U) tr2 st2' m2' /\
      inject_incr mu mu'.
      Proof.
        intros * Hconcur Htrace Hchs_peek Hresume.

        assert (Hcnt2: containsThread st2 tid).
        { eapply contains12; eauto. }
        
        (* destruct {tid < hb} + {tid = hb} + {hb < tid}  *)
        destruct (Compare_dec.lt_eq_lt_dec tid hb) as [[?|?]|?].
        - (* tid < hb *)
          intros. inv Hresume.
          hnf in Hperm; subst m'.

          (* get the match for this thread *)
          exploit @mtch_target; eauto.
          simpl in *; rewrite Hcode.
          intros HH.
          hnf in HH. inv HH; simpl in *.
          destruct H3 as  (Hasm_match & Hmem_match).

          (* get the first after_external*)
          revert Hafter_external.
          unfold after_external_sum,
          state_sum_optiont,
          sum_func_option,
          state_sum_options.
          match_case. intros HH; inv HH.

          (* get the second after_external, construct the new state*)
          assert (ssim_after_ext:
                    forall (f : meminj)
                      (c1 c1' : Smallstep.state (Asm.part_semantics Asm_g))
                      (m1 : mem)
                      (c2 : Smallstep.state (Asm.part_semantics Asm_g))
                      (m2 : mem),
                      match_self (code_inject _ _ Aself_simulation) f c1 m1 c2 m2 ->
                      Asm.after_external Asm_g None c1 m1 = Some c1' ->
                      exists (c2' : Smallstep.state (Asm.part_semantics Asm_g)),
                        Asm.after_external Asm_g None c2 m2 = Some c2' /\
                        match_self (code_inject _ _ Aself_simulation) f c1' m1 c2' m2).
          { admit. }
          exploit ssim_after_ext; simpl.
          2:{ eauto. }
          { econstructor; eauto. }
          intros; normal_hyp. destruct H0 as (Hasm_match' & Hmem_match').

          (* get the second at_external*)
          destruct X as (FUN & args).
          exploit ssim_external; simpl; try exact Hasm_match;
            eauto.
          { eapply Hconcur. }
          { simpl; eauto. }
          intros ; normal_hyp.

                        
          
          intros; normal; eauto.
          + unshelve eapply concur_match_updateC; eauto; shelve_unifiable.
            hnf; simpl.

            econstructor 2; eauto.
            econstructor; econstructor; eauto.
            unfold Asm_code_inject; simpl.
            clean_proofs; eauto.
            unfold thmem_from_concur1, thmem_from_concur2.
            instantiate(1:= (th_comp
                               (mem_compatible_thread_compat st2 m2 tid Hcnt2
             (memcompat2 Hconcur)))) in Hmem_match'.
            revert Hmem_match'; clean_proofs_goal; eauto.
          + replace U with
                (@HybridMachineSig.yield HybridMachineSig.HybridCoarseMachine.scheduler U)
              by reflexivity.
            unshelve eapply HybridMachineSig.resume_step'; eauto.
            econstructor.
            * simpl. reflexivity.
            * simpl.
              instantiate(3:=TST code2); simpl. simpl in H2; eauto.
            * simpl; eauto.
              unfold state_sum_optiont. simpl in H.
              instantiate(2:= (memcompat2 Hconcur)).
              revert H; clean_proofs_goal.
              intros Hafter. unfold Asm_g in *; rewrite Hafter.
              reflexivity.
            * simpl; eauto. 
            * eapply Hconcur.
            * simpl. eauto.
              
        - (* tid = hb *)
          subst.
          inversion Hresume; subst.
          inversion Hconcur. simpl in *.
          assert (m1_restr: permMapLt (thread_perms _ _ ctn) (getMaxPerm m1')) by
              eapply memcompat1.
          assert (m2_restr: permMapLt (thread_perms _ _ Hcnt2) (getMaxPerm m2)) by
              eapply memcompat2.
          specialize (mtch_compiled hb ltac:(reflexivity) ctn Hcnt2
                                                          m1_restr
                                                          m2_restr).
          rewrite Hcode in mtch_compiled.
          inv mtch_compiled.
          
          (* TODO: Add the precondition of H10 to the concur match.
             that means: assert all the preconditions for the current state,
             and also have the precondition for all future states that satisfy the hyps.
             
             WAIT: Maybe not, I think you just need to instantiate it with the 
             current values. All the precontidions are refelxive.

           *)
          simpl in H6.
          inv Hafter_external.
          erewrite (restr_proof_irr m1_restr) in H6.
          destruct ((Clight.after_external None code1 m')) eqn:Hafter_x1; inv H0.
          rewrite Hperm in Hafter_x1.
          specialize (H6 mu s (restrPermMap _) (restrPermMap m2_restr) nil nil
                          ltac:(constructor)
                                 ltac:(constructor)
                                        ltac:(constructor)
                                               Hafter_x1
                     ).
          destruct H6 as (cd' & mu' & s2' & Hafter_x2 & INJ1 & Hcompiler_match).
          remember 
            (updThreadC Hcnt2 (Krun (TState Clight.state Asm.state s2'))) as st2'.
          exists st2',m2,(Some cd0), mu'. 
          repeat weak_split.
          + !goal (concur_match _ mu' _ _ _ _).
            (* subst st2'.
            unshelve eapply @concur_match_updateC; eauto. eauto.
            eapply Hconcur. *)
            
            
            admit.
          + !goal (Forall2 (inject_mevent mu') tr1 tr2).
            admit.
          + (* Step *)
            !goal (HybridMachineSig.external_step _ _ _ _ _ _ _ _).
            assert (HH: U = (HybridMachineSig.yield
                               (Scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler) U))
              by reflexivity.
            rewrite HH at 2.
            eapply HybridMachineSig.resume_step'; eauto.
            admit.
          + assumption.
        (* econstructor; eauto. *)

        - (* hb < tid *)
          admit.
      Admitted.

      
      
      
      Lemma suspend_step_diagram:
        forall (m : option mem) (tge : HybridMachineSig.G) 
               (U : list nat) (st1 : ThreadPool (Some hb))
               (tr1 tr2 : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some hb)) (m1' : mem)
               (cd : option compiler_index) (st2 : ThreadPool (Some (S hb)))
               (mu : meminj) (m2 : mem) (tid : nat)
               (Htid : ThreadPool.containsThread st1 tid),
          concur_match cd mu st1 m1' st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          HybridMachineSig.schedPeek U = Some tid ->
          HybridMachineSig.suspend_thread m1' Htid st1' ->
          exists
            (st2' : ThreadPool (Some (S hb))) (m2' : mem) 
            (cd' : option compiler_index) (mu' : meminj),
            concur_match cd' mu' st1' m1' st2' m2' /\
            List.Forall2 (inject_mevent mu') tr1 tr2 /\
            machine_semantics.machine_step (HybConcSem (Some (S hb)) m) tge
                                           U tr2 st2 m2 (HybridMachineSig.schedSkip U) tr2 st2' m2'/\
      inject_incr mu mu'.
      Proof.
        admit. (* Easy  since there is no changes to memory. *)
      Admitted.

      Lemma schedfail_step_diagram:
        forall (m : option mem) (tge : HybridMachineSig.G) 
               (U : list nat) (tr1 tr2 : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some hb)) (m1' : mem)
               (st2 : ThreadPool (Some (S hb))) (m2 : mem) 
               (tid : nat) cd mu,
          concur_match cd mu st1' m1' st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          HybridMachineSig.schedPeek U = Some tid ->
          (~ ThreadPool.containsThread st1' tid \/
         (exists (cnt : ThreadPool.containsThread st1' tid) (c : semC) i,
             ThreadPool.getThreadC cnt = Krun c /\
             halted (sem_coresem (HybridSem (Some hb))) c i)) ->
          HybridMachineSig.invariant st1' ->
          HybridMachineSig.mem_compatible st1' m1' ->
          exists
            (st2' : ThreadPool (Some (S hb))) (m2' : mem) 
            (cd' : option compiler_index) (mu' : meminj),
            concur_match cd' mu' st1' m1' st2' m2' /\
            List.Forall2 (inject_mevent mu') tr1 tr2 /\
            machine_semantics.machine_step (HybConcSem (Some (S hb)) m) tge
                                           U tr2 st2 m2 U tr2 st2' m2'
      /\
      inject_incr mu mu'.
      Proof.
        admit.
        (* Easy  since there is no changes to memory. *)
      Admitted.
      
      Lemma machine_step_diagram:
        forall (m : option mem) (sge tge : HybridMachineSig.G) (U : list nat)
               (tr1 : HybridMachineSig.event_trace) (st1 : ThreadPool (Some hb)) 
               (m1 : mem) (U' : list nat) (tr1' : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some hb)) (m1' : mem),
          machine_semantics.machine_step (HybConcSem (Some hb) m) sge U tr1 st1 m1 U' tr1' st1' m1' ->
          forall (cd : option compiler_index) tr2 (st2 : ThreadPool (Some (S hb))) 
                 (mu : meminj) (m2 : mem)
                 (Hinv:invariant st1') (Hcmpt':mem_compatible st1' m1'),
            concur_match cd mu st1 m1 st2 m2 ->
            List.Forall2 (inject_mevent mu) tr1 tr2 ->
            exists
              tr2' (st2' : ThreadPool (Some (S hb))) (m2' : mem) (cd' : option compiler_index) 
              (mu' : meminj),
              concur_match cd' mu' st1' m1' st2' m2' /\
              List.Forall2 (inject_mevent mu') tr1' tr2' /\
              machine_semantics.machine_step (HybConcSem (Some (S hb)) m) tge U tr2 st2 m2 U' tr2' st2'
                                             m2' /\
              inject_incr mu mu'.
      Proof.
        intros; simpl in H. 
        inversion H; subst.
        - (* Start thread. *)
          exists tr2; eapply start_step_diagram; eauto.
          
        - (* resume thread. *)
          exists tr2; eapply resume_step_diagram; eauto.
          
        - (* suspend thread. *)
          exists tr2; eapply suspend_step_diagram; eauto.
          
        - (* sync step. *)
          edestruct external_step_diagram as (? & ? & ? & ? & ? & ? & ? & ?); eauto 8.

        - (*schedfail. *) 
          exploit schedfail_step_diagram; eauto.

          
      Qed.


      
      Lemma initial_diagram:
        forall (m : option mem) (s_mem s_mem' : mem) (main : val) (main_args : list val)
               (s_mach_state : ThreadPool (Some hb)) (r1 : option res),
          machine_semantics.initial_machine (HybConcSem (Some hb) m) r1 s_mem s_mach_state s_mem'
                                            main main_args ->
          exists
            (j : meminj) (cd : option compiler_index) (t_mach_state : ThreadPool (Some (S hb))) 
            (t_mem t_mem' : mem) (r2 : option res),
            machine_semantics.initial_machine (HybConcSem (Some (S hb)) m) r2 t_mem t_mach_state
                                              t_mem' main main_args /\ concur_match cd j s_mach_state s_mem' t_mach_state t_mem'.
      Proof.
        intros m.
        
        simpl; unfold HybridMachineSig.init_machine''.
        intros ? ? ? ? ? ? (?&?).
        destruct r1; try solve[inversion H0].
        simpl in H0.
        destruct H0 as (init_thread&?&?); simpl in *.
        unfold initial_core_sum in *.
        destruct init_thread; destruct H0 as (LT&H0); simpl in LT.
        + admit. (*identical start!*)
        + admit. (*should follow from compiler simulation*)
      Admitted.

      Lemma compile_one_thread:
        forall m ,
          simulation_properties_exposed
            (HybConcSem (Some hb) m)
            (HybConcSem (Some (S hb)) m)
            invariant
            mem_compatible
            (concur_match)
            (opt_rel' (InjorderX compiler_sim)).
      Proof.
        intros.
        unshelve econstructor;
          [econstructor| reflexivity].
        - eapply option_wf.
          eapply (Injfsim_order_wfX compiler_sim). (*well_founded order*)

        (*Initial Diagram*)
        - eapply initial_diagram.

        (* Internal Step diagram*)
        - eapply internal_step_diagram.

        (* Machine Step diagram *)
        - eapply machine_step_diagram.

        (* Halted *)
        - simpl; unfold HybridMachineSig.halted_machine; simpl; intros.
          destruct (HybridMachineSig.schedPeek U); inversion H0.
          eexists; reflexivity.

        (*Same running *)
        - eapply concur_match_same_running.
      Qed.
      
      
    End CompileOneThread.

  End ThreadedSimulation.
End ThreadedSimulation.
