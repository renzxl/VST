Require Import VST.floyd.proofauto.
Require Import VST.progs.printf.
Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.

Require Import VST.floyd.printf.
Require Import VST.floyd.io_events.
Require Import ITree.ITree.
Require Import ITree.Eq.Eq.
(*Import ITreeNotations.*)
Notation "t1 ;; t2" := (ITree.bind t1 (fun _ => t2))
  (at level 100, right associativity) : itree_scope.

Instance nat_id : FileId := { file_id := nat; FILEid := ___sFILE; get_file_id f := O; stdout := tt }.

Definition stdout := O.

Definition main_spec :=
 DECLARE _main
  WITH gv : globals
  PRE  [] main_pre_ext prog (write_list stdout (string2bytes "Hello, world!
");; write_list stdout (string2bytes "This is line 2.
")) nil gv
  POST [ tint ] main_post prog nil gv.

Definition Gprog : funspecs :=  
   ltac:(with_library prog (ltac:(make_printf_specs prog) ++ [ main_spec ])).

Lemma bind_ret' : forall E (s : itree E unit), eutt eq (s;; Ret tt) s.
Proof.
  intros.
  etransitivity; [|apply eq_sub_eutt, bind_ret2].
  apply eqit_bind; [intros []|]; reflexivity.
Qed.

Lemma body_main: semax_body Vprog Gprog f_main main_spec.
Proof.
start_function.
repeat do_string2bytes.
repeat (sep_apply data_at_to_cstring; []).
replace_SEP 3 (ITREE (write_list stdout (string2bytes "Hello, world!
");; write_list stdout (string2bytes "This is line 2.
"))).
{ go_lower; apply has_ext_ITREE. }
forward_printf tt (write_list stdout (string2bytes "This is line 2.
")).
{ rewrite sepcon_comm; apply sepcon_derives; cancel.
  apply derives_refl. }
forward_fprintf (gv __stdout) ((Ers, string2bytes "line", gv ___stringlit_2), (Int.repr 2, tt)) (tt, Ret tt : @IO_itree file_id).
{ (* need to know that stdout actually points to a file object? or should that be a dummy? *)
  rewrite <- emp_sepcon at 1.
  rewrite !sepcon_assoc; apply sepcon_derives; [admit|].
  rewrite sepcon_comm; apply sepcon_derives; cancel.
  apply ITREE_impl.
  rewrite bind_ret'; reflexivity. }
forward.
Admitted.
