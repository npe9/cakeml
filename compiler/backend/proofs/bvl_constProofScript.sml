open preamble bvl_constTheory bvlSemTheory bvlPropsTheory;

val _ = new_theory"bvl_constProof";

val ind = evaluate_ind
  |> Q.SPECL [`\(xs,env,s). (FST (evaluate (xs,env,s)) <> Rerr(Rabort Rtype_error)) ==>
                            evaluate (compile_exps xs,env,s) = evaluate (xs,env,s)`]
  |> SIMP_RULE std_ss []

val bEval_cons = evaluate_CONS;
val bEval_def = evaluate_def;
val bEvalOp_def = do_app_def;

val compile_exps_thm = store_thm("compile_exps_thm",
  ``!xs env s.
      (FST (evaluate (xs,env,s)) <> Rerr(Rabort Rtype_error)) ==>
      (evaluate (compile_exps xs,env,s) = evaluate (xs,env,s))``,
  HO_MATCH_MP_TAC ind \\ REPEAT STRIP_TAC
  \\ SIMP_TAC std_ss [compile_exps_def,LET_DEF]
  \\ POP_ASSUM MP_TAC
  THEN1
   (SIMP_TAC std_ss [Once bEval_cons]
    \\ ONCE_REWRITE_TAC [EQ_SYM_EQ]
    \\ SIMP_TAC std_ss [Once bEval_cons]
    \\ FULL_SIMP_TAC std_ss [compile_exp_SING]
    \\ BasicProvers.EVERY_CASE_TAC
    \\ FULL_SIMP_TAC (srw_ss()) [compile_exps_def,bEval_def]
    \\ REV_FULL_SIMP_TAC (srw_ss()) [compile_exps_def])
  THEN1
   (SRW_TAC [] [] \\ POP_ASSUM MP_TAC \\ fs [bEval_def]
    \\ Cases_on `evaluate ([x1],env,s)` \\ fs []
    \\ reverse (Cases_on `q`) \\ fs []
    \\ fs [GSYM compile_exp_SING,EVAL ``Bool T``,EVAL ``Bool F``]
    \\ fs [bEval_def,bEvalOp_def] \\ SRW_TAC [] []
    \\ fs [EVAL ``Boolv T``,EVAL ``Boolv F``])
  \\ TRY
   (ASM_SIMP_TAC std_ss [bEval_def]
    \\ BasicProvers.EVERY_CASE_TAC
    \\ FULL_SIMP_TAC (srw_ss()) [GSYM compile_exp_SING]
    \\ REV_FULL_SIMP_TAC (srw_ss()) [] \\ NO_TAC)
  \\ SIMP_TAC std_ss [bEval_def,compile_op_def]
  \\ reverse (Cases_on `EVERY isConst (compile_exps xs)`)
  THEN1 (FULL_SIMP_TAC std_ss [bEval_def]
         \\ Cases_on `evaluate (xs,env,s)` \\ FULL_SIMP_TAC (srw_ss()) []
         \\ Cases_on `q` \\ FULL_SIMP_TAC (srw_ss()) [])
  \\ Cases_on `?s1. evaluate (xs,env,s) = (Rerr(Rabort Rtype_error),s1)` \\ fs [LET_DEF]
  \\ Cases_on `evaluate (xs,env,s)` \\ fs []
  \\ IMP_RES_TAC evaluate_isConst
  \\ FULL_SIMP_TAC std_ss []
  \\ SRW_TAC [] []
  \\ Cases_on `op` \\ FULL_SIMP_TAC (srw_ss()) [bEval_def]
  \\ Cases_on `xs` \\ fs [compile_exps_def,bEvalOp_def]
  \\ Cases_on `t` \\ fs [compile_exps_def,bEvalOp_def]
  \\ `t' = []` by ALL_TAC \\ fs [compile_exps_def] \\ SRW_TAC [] [] \\ fs []
  \\ Cases_on `REVERSE (MAP (Number o getConst) (compile_exps t'))` \\ fs []
  \\ TRY (Cases_on `t'` \\ fs [compile_exps_def] \\ NO_TAC)
  \\ TRY (simp[Boolv_def] \\ NO_TAC)
  \\ Cases_on `h''` \\ fs []
  \\ Cases_on `t` \\ fs []
  \\ Cases_on `h''` \\ fs []
  \\ Cases_on `t''` \\ fs []);

(* these theorems are unnecessary, since bvl_handle happens after bvl_const
val compile_exps_bVarBound = Q.store_thm("compile_exps_bVarBound",
  `(∀es n. bVarBound n es ⇒ bVarBound n (compile_exps es)) ∧
   (∀e n. bVarBound n [e] ⇒ bVarBound n [compile_exp e])`,
  ho_match_mp_tac compile_exps_ind >>
  rw[compile_exps_def] >> rw[] >> fs[] >> rfs[] >>
  fs[bVarBound_def,clos_to_bvlTheory.Bool_def] >>
  TRY (
    CHANGED_TAC(rw[compile_op_def]) >>
    BasicProvers.CASE_TAC >> rw[] ) >>
  fs[Once bVarBound_EVERY] >>
  METIS_TAC[bVarBound_EVERY]);

val compile_exps_isVar = Q.store_thm("compile_exps_isVar",
  `(∀es. EVERY isVar es ⇒ EVERY isVar (compile_exps es)) ∧
   (∀e. isVar e ⇒ isVar (compile_exp e))`,
  ho_match_mp_tac compile_exps_ind >>
  rw[compile_exps_def,isVar_def]);

val compile_exps_GoodHandleLet = Q.store_thm("compile_exps_GoodHandleLet",
  `(∀es.  bEvery GoodHandleLet es ⇒ bEvery GoodHandleLet (compile_exps es)) ∧
   (∀e. bEvery GoodHandleLet [e] ⇒ bEvery GoodHandleLet [compile_exp e])`,
  ho_match_mp_tac compile_exps_ind >>
  rw[compile_exps_def] >> rw[] >> fs[] >>
  TRY (
    CHANGED_TAC(rw[compile_op_def]) >>
    BasicProvers.CASE_TAC >> rw[] ) >>
  TRY (
    qmatch_assum_rename_tac`GoodHandleLet (Handle e1 e2)` >>
    Cases_on`e1`>>fs[compile_exps_def] >>
    imp_res_tac compile_exps_bVarBound >>
    imp_res_tac compile_exps_isVar >>
    imp_res_tac compile_exps_bVarBound >>
    fs[compile_exps_SING] ) >>
  fs[Once bEvery_EVERY] >>
  METIS_TAC[bEvery_EVERY]);
*)

val _ = export_theory();
