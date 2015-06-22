open preamble
     bvlSemTheory bvlPropsTheory
     bvl_to_bviTheory
     bviSemTheory bviPropsTheory;

val _ = new_theory"bvl_to_bviProof";

(* TODO: move *)

val FLOOKUP_FAPPLY = FLOOKUP_UPDATE;

val IMP_EVERY_LUPDATE = prove(
  ``!xs h i. P h /\ EVERY P xs ==> EVERY P (LUPDATE h i xs)``,
  Induct \\ fs [LUPDATE_def] \\ REPEAT STRIP_TAC
  \\ Cases_on `i` \\ fs [LUPDATE_def]);

val MEM_EQ_IMP_MAP_EQ = MAP_EQ_f;

val MAP_APPEND_MAP_EQ = prove(
  ``!xs ys.
      ((MAP f1 xs ++ MAP g1 ys) = (MAP f2 xs ++ MAP g2 ys)) <=>
      (MAP f1 xs = MAP f2 xs) /\ (MAP g1 ys = MAP g2 ys)``,
  Induct \\ fs [] \\ METIS_TAC []);

val LUPDATE_SOME_MAP = prove(
  ``!xs n f h.
      LUPDATE (SOME (f h)) n (MAP (OPTION_MAP f) xs) =
      MAP (OPTION_MAP f) (LUPDATE (SOME h) n xs)``,
  Induct THEN1 (EVAL_TAC \\ fs []) \\ Cases_on `n` \\ fs [LUPDATE_def]);

val IN_INSERT_EQ = prove(
  ``n IN s ==> (n INSERT s = s)``,
  fs [EXTENSION] \\ METIS_TAC []);

val MAP_LUPDATE = prove(
  ``!xs y x f. MAP f (LUPDATE x y xs) = LUPDATE (f x) y (MAP f xs)``,
  Induct THEN1 (EVAL_TAC \\ fs []) \\ Cases_on `y` \\ fs [LUPDATE_def]);

val INJ_EXTEND = prove(
  ``INJ b s t /\ ~(x IN s) /\ ~(y IN t) ==>
    INJ ((x =+ y) b) (x INSERT s) (y INSERT t)``,
  fs [INJ_DEF,APPLY_UPDATE_THM] \\ METIS_TAC []);

(* -- *)

(* value relation *)

val bVarBound_def = tDefine "bVarBound" `
  (bVarBound n [] <=> T) /\
  (bVarBound n ((x:bvl$exp)::y::xs) <=>
     bVarBound n [x] /\ bVarBound n (y::xs)) /\
  (bVarBound n [Var v] <=> v < n) /\
  (bVarBound n [If x1 x2 x3] <=>
     bVarBound n [x1] /\ bVarBound n [x2] /\ bVarBound n [x3]) /\
  (bVarBound n [Let xs x2] <=>
     bVarBound n xs /\ bVarBound (n + LENGTH xs) [x2]) /\
  (bVarBound n [Raise x1] <=> bVarBound n [x1]) /\
  (bVarBound n [Tick x1] <=>  bVarBound n [x1]) /\
  (bVarBound n [Op op xs] <=> bVarBound n xs) /\
  (bVarBound n [Handle x1 x2] <=>
     bVarBound n [x1] /\ bVarBound (n + 1) [x2]) /\
  (bVarBound n [Call ticks dest xs] <=> bVarBound n xs)`
  (WF_REL_TAC `measure (exp1_size o SND)`
   \\ REPEAT STRIP_TAC \\ TRY DECIDE_TAC
   \\ SRW_TAC [] [bvlTheory.exp_size_def] \\ DECIDE_TAC);

val GoodHandleLet_def = Define `
  (GoodHandleLet ((Handle (Let xs b) y):bvl$exp) <=>
     EVERY isVar xs /\ bVarBound (LENGTH xs) [b]) /\
  (GoodHandleLet ((Handle _ y):bvl$exp) <=> F) /\
  (GoodHandleLet _ <=> T)`;

val bEvery_def = tDefine "bEvery" `
  (bEvery P [] <=> T) /\
  (bEvery P ((x:bvl$exp)::y::xs) <=>
     bEvery P [x] /\ bEvery P (y::xs)) /\
  (bEvery P [Var v] <=> P (Var v)) /\
  (bEvery P [If x1 x2 x3] <=> P (If x1 x2 x3) /\
     bEvery P [x1] /\ bEvery P [x2] /\ bEvery P [x3]) /\
  (bEvery P [Let xs x2] <=> P (Let xs x2) /\
     bEvery P xs /\ bEvery P [x2]) /\
  (bEvery P [Raise x1] <=> P (Raise x1) /\ bEvery P [x1]) /\
  (bEvery P [Tick x1] <=> P (Tick x1) /\ bEvery P [x1]) /\
  (bEvery P [Op op xs] <=> P (Op op xs) /\ bEvery P xs) /\
  (bEvery P [Handle x1 x2] <=> P (Handle x1 x2) /\
     bEvery P [x1] /\ bEvery P [x2]) /\
  (bEvery P [Call ticks dest xs] <=> P (Call ticks dest xs) /\ bEvery P xs)`
  (WF_REL_TAC `measure (exp1_size o SND)`
   \\ REPEAT STRIP_TAC \\ TRY DECIDE_TAC
   \\ SRW_TAC [] [bvlTheory.exp_size_def] \\ DECIDE_TAC);

val adjust_bv_def = tDefine "adjust_bv" `
  (adjust_bv b (Number i) = Number i) /\
  (adjust_bv b (RefPtr r) = RefPtr (b r)) /\
  (adjust_bv b (CodePtr c) = CodePtr (2 * c)) /\
  (adjust_bv b (Block tag vs) = Block tag (MAP (adjust_bv b) vs))`
  (WF_REL_TAC `measure (v_size o SND)`
   \\ Induct_on `vs` \\ fs [] \\ SRW_TAC [] [v_size_def]
   \\ RES_TAC \\ FIRST_X_ASSUM (ASSUME_TAC o SPEC_ALL) \\ DECIDE_TAC)

val adjust_bv_ind = theorem"adjust_bv_ind";

val adjust_bv_Unit = Q.store_thm("adjust_bv_Unit[simp]",
  `adjust_bv x Unit = Unit`,
  EVAL_TAC);

val adjust_bv_Boolv = store_thm("adjust_bv_Boolv[simp]",
  ``adjust_bv x (Boolv b) = Boolv b``,
  Cases_on`b`>>EVAL_TAC)

val aux_code_installed_def = Define `
  (aux_code_installed [] t <=> T) /\
  (aux_code_installed ((name,arg_count,body)::rest) t <=>
     (sptree$lookup (2 * name + 1) t = SOME (arg_count,body)) /\
     aux_code_installed rest t)`

val aux_code_installed_APPEND = prove(
  ``!xs ys.
      aux_code_installed (xs++ys) code ==>
      aux_code_installed xs code /\
      aux_code_installed ys code``,
  Induct \\ fs [APPEND,aux_code_installed_def,FORALL_PROD] \\ METIS_TAC []);

val state_rel_def = Define `
  state_rel (b:num->num) (s:bvlSem$state) (t:bviSem$state) <=>
    INJ b (FDOM s.refs) (FDOM t.refs) /\
    (!k. case FLOOKUP s.refs k of
         | NONE => T
         | SOME (ValueArray vs) =>
             (FLOOKUP t.refs (b k) = SOME (ValueArray (MAP (adjust_bv b) vs)))
         | SOME res => (FLOOKUP t.refs (b k) = SOME res)) /\
    (s.io = t.io) /\
    (t.globals = MAP (OPTION_MAP (adjust_bv b)) s.globals) /\
    (s.clock = t.clock) /\
    (!name arity exp.
       (lookup name s.code = SOME (arity,exp)) ==>
       ?n. let (c1,aux1,n1) = compile n [exp] in
             (lookup (2 * name) t.code = SOME (arity,HD c1)) /\
             aux_code_installed aux1 t.code /\
             bEvery GoodHandleLet [exp])`;

val bv_ok_def = tDefine "bv_ok" `
  (bv_ok refs (RefPtr r) <=> r IN FDOM refs) /\
  (bv_ok refs (Block tag vs) <=> EVERY (bv_ok refs) vs) /\
  (bv_ok refs _ <=> T)`
  (WF_REL_TAC `measure (v_size o SND)`
   \\ Induct_on `vs` \\ fs [] \\ SRW_TAC [] [v_size_def]
   \\ RES_TAC \\ FIRST_X_ASSUM (ASSUME_TAC o SPEC_ALL) \\ DECIDE_TAC)

val bv_ok_ind = theorem"bv_ok_ind";

val bv_ok_SUBSET_IMP = prove(
  ``!refs x refs2.
      bv_ok refs x /\ FDOM refs SUBSET FDOM refs2 ==> bv_ok refs2 x``,
  HO_MATCH_MP_TAC bv_ok_ind \\ fs [bv_ok_def]
  \\ fs [SUBSET_DEF,EVERY_MEM]);

val bv_ok_Unit = Q.store_thm("bv_ok_Unit[simp]",
  `bv_ok refs Unit`,
  EVAL_TAC)

val bv_ok_Boolv = Q.store_thm("bv_ok_Boolv[simp]",
  `bv_ok refs (Boolv b)`,
  EVAL_TAC)

val bv_ok_IMP_adjust_bv_eq = prove(
  ``!b2 a1 b3.
      bv_ok (s5:bvlSem$state).refs a1 /\
      (!a. a IN FDOM s5.refs ==> b2 a = b3 a) ==>
      (adjust_bv b2 a1 = adjust_bv b3 a1)``,
  HO_MATCH_MP_TAC adjust_bv_ind
  \\ REPEAT STRIP_TAC \\ fs [adjust_bv_def,bv_ok_def]
  \\ fs [MEM_EQ_IMP_MAP_EQ,EVERY_MEM]);

val state_ok_def = Define `
  state_ok (s:bvlSem$state) <=>
    EVERY (\x. case x of NONE => T | SOME v => bv_ok s.refs v) s.globals /\
    !k. case FLOOKUP s.refs k of
        | SOME (ValueArray vs) => EVERY (bv_ok s.refs) vs
        | _ => T`;

(* evaluate preserves state_ok *)

val evaluate_ok_lemma = prove(
  ``(state_ok (dec_clock n s) = state_ok s) /\
    ((dec_clock n s).refs = s.refs)``,
  fs [state_ok_def,bvlSemTheory.dec_clock_def]);

val evaluate_IMP_bv_ok = prove(
  ``(bvlSem$evaluate (xs,env,s) = (res,t)) ==>
    (bv_ok s.refs a1 ==> bv_ok t.refs a1) /\
    (EVERY (bv_ok s.refs) as ==> EVERY (bv_ok t.refs) as)``,
  REPEAT STRIP_TAC \\ fs [EVERY_MEM] \\ REPEAT STRIP_TAC \\ RES_TAC
  \\ IMP_RES_TAC evaluate_refs_SUBSET \\ IMP_RES_TAC bv_ok_SUBSET_IMP);

val v_to_list_ok = Q.prove(
  `∀v x. v_to_list v = SOME x ∧
         bv_ok refs v ⇒
         EVERY (bv_ok refs) x`,
  ho_match_mp_tac v_to_list_ind >>
  simp[v_to_list_def,bv_ok_def] >> rw[] >>
  every_case_tac >> fs[] >> rw[])

val do_app_ok_lemma = prove(
  ``state_ok r /\ EVERY (bv_ok r.refs) a /\
    (do_app op a r = Rval (q,t)) ==>
    state_ok t /\ bv_ok t.refs q``,
  Cases_on `op` \\ fs [bvlSemTheory.do_app_def] \\ BasicProvers.EVERY_CASE_TAC
  \\ TRY (fs [] \\ SRW_TAC [] [bv_ok_def]
    \\ fs [closSemTheory.get_global_def]
    \\ fs [state_ok_def,bv_ok_def] \\ NO_TAC)
  \\ TRY (SRW_TAC [] [] \\ fs [bv_ok_def,EVERY_EL] \\ NO_TAC)
  \\ TRY (SRW_TAC [] [] \\ fs [bv_ok_def,EVERY_MEM] \\ NO_TAC)
  \\ STRIP_TAC \\ fs [LET_THM] \\ rpt BasicProvers.VAR_EQ_TAC THEN1
   (fs [closSemTheory.get_global_def,state_ok_def,EVERY_EL]
    \\ RES_TAC \\ fs [] \\ REPEAT (Q.PAT_ASSUM `!x.bb` (K ALL_TAC))
    \\ REV_FULL_SIMP_TAC std_ss [])
  THEN1
   (SRW_TAC [] [bv_ok_def] \\ fs [LET_DEF,state_ok_def]
    \\ MATCH_MP_TAC IMP_EVERY_LUPDATE \\ fs [])
  THEN1
   (rw[bv_ok_def] \\ fs [state_ok_def] >>
    rw[FLOOKUP_UPDATE] >> fs[EVERY_MEM] >> rw[] >>
    BasicProvers.CASE_TAC >> TRY BasicProvers.CASE_TAC >> rw[] >>
    MATCH_MP_TAC (Q.ISPEC`(r:bvlSem$state).refs`bv_ok_SUBSET_IMP) >>
    first_x_assum(qspec_then`k`strip_assume_tac)>>rfs[]>>
    simp[] >> res_tac >> fs[] >>
    simp[SUBSET_DEF])
  THEN1
   (rw[bv_ok_def] \\ fs [state_ok_def] >>
    rw[FLOOKUP_UPDATE] >> fs[EVERY_MEM] >> rw[] >>
    rpt BasicProvers.CASE_TAC >> rw[] >>
    MATCH_MP_TAC (Q.ISPEC`(r:bvlSem$state).refs`bv_ok_SUBSET_IMP) >>
    first_x_assum(qspec_then`k`strip_assume_tac)>>rfs[]>>
    simp[] >> res_tac >> fs[rich_listTheory.REPLICATE_GENLIST,MEM_GENLIST] >>
    simp[SUBSET_DEF])
  THEN1
   (rw[bv_ok_def] \\ fs [state_ok_def] >>
    rw[FLOOKUP_UPDATE] >> fs[EVERY_MEM] >> rw[] >>
    every_case_tac >> rw[] >>
    MATCH_MP_TAC (Q.ISPEC`(r:bvlSem$state).refs`bv_ok_SUBSET_IMP) >>
    first_x_assum(qspec_then`k`strip_assume_tac)>>rfs[]>>
    simp[] >> res_tac >> fs[] >>
    simp[SUBSET_DEF])
  THEN1 (
    simp[bv_ok_def] >>
    imp_res_tac v_to_list_ok >>
    fs[EVERY_MEM])
  THEN1
   (fs [LET_DEF,state_ok_def]
    \\ SRW_TAC [] [bv_ok_def,FLOOKUP_DEF,EVERY_MEM]
    \\ BasicProvers.EVERY_CASE_TAC
    \\ fs [EVERY_MEM] \\ RES_TAC \\ fs []
    \\ REPEAT STRIP_TAC \\ RES_TAC
    THEN1 (MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
           \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF])
    THEN1 (MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
           \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF])
    \\ Q.PAT_ASSUM `xx = ValueArray l` MP_TAC
    \\ SRW_TAC [] [FAPPLY_FUPDATE_THM] \\ RES_TAC
    THEN1 (MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
           \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF])
    \\ Q.PAT_ASSUM `!k:num. bbb` (MP_TAC o Q.SPEC `k`)
    \\ fs [FLOOKUP_DEF] \\ REPEAT STRIP_TAC
    THEN1 (MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
           \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF]))
  THEN1
   (fs [state_ok_def]
    \\ Q.PAT_ASSUM `!k:num. bbb` (MP_TAC o Q.SPEC `n`) \\ fs []
    \\ fs [EVERY_EL] \\ REPEAT STRIP_TAC \\ RES_TAC
    \\ SRW_TAC [] [] \\ Cases_on `i` \\ fs [])
  THEN1
   (fs [state_ok_def] \\ SRW_TAC [] [] THEN1
     (fs [EVERY_MEM] \\ REPEAT STRIP_TAC
      \\ BasicProvers.EVERY_CASE_TAC
      \\ RES_TAC \\ fs []
      \\ MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
      \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF])
    THEN1
     (fs [FLOOKUP_FAPPLY] \\ Cases_on `k = n` \\ fs [] THEN1
       (MATCH_MP_TAC IMP_EVERY_LUPDATE \\ REPEAT STRIP_TAC
        THEN1 (MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
          \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF])
        \\ Q.PAT_ASSUM `!k:num. bbb` (MP_TAC o Q.SPEC `n`) \\ fs []
        \\ fs [EVERY_MEM] \\ REPEAT STRIP_TAC \\ RES_TAC
        \\ MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
        \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF])
      \\ Q.PAT_ASSUM `!k:num. bbb` (MP_TAC o Q.SPEC `k`) \\ fs []
      \\ BasicProvers.EVERY_CASE_TAC
      \\ fs [EVERY_MEM] \\ REPEAT STRIP_TAC \\ RES_TAC
      \\ MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
      \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF]))
  THEN1 (
    fs[state_ok_def] \\ rw[] >-
     (fs [EVERY_MEM] \\ REPEAT STRIP_TAC
      \\ BasicProvers.EVERY_CASE_TAC
      \\ RES_TAC \\ fs []
      \\ MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
      \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF])
    \\ simp[FLOOKUP_UPDATE] >> rw[] >>
    BasicProvers.CASE_TAC >>
    BasicProvers.CASE_TAC >>
    first_x_assum(qspec_then`k`mp_tac) >> rw[] >>
    fs [EVERY_MEM] \\ REPEAT STRIP_TAC
    \\ RES_TAC \\ fs []
    \\ MATCH_MP_TAC (bv_ok_SUBSET_IMP |> Q.ISPEC `(r:bvlSem$state).refs`)
    \\ fs [] \\ fs [SUBSET_DEF,FLOOKUP_DEF]));

val do_app_ok = prove(
  ``state_ok r /\ EVERY (bv_ok r.refs) a /\
    (do_app op a r = Rval (q,t)) ==>
    state_ok t /\ bv_ok t.refs q /\
    (EVERY (bv_ok r.refs) env ==> EVERY (bv_ok t.refs) env)``,
  STRIP_TAC \\ IMP_RES_TAC do_app_ok_lemma \\ fs []
  \\ fs [EVERY_MEM] \\ REPEAT STRIP_TAC \\ RES_TAC
  \\ IMP_RES_TAC do_app_refs_SUBSET
  \\ IMP_RES_TAC bv_ok_SUBSET_IMP);

val evaluate_ok = prove(
  ``!xs env s res t.
      (evaluate (xs,env,s) = (res,t)) /\
      state_ok s /\ EVERY (bv_ok s.refs) env ==>
      state_ok t /\
      (case res of
       | Rval vs => EVERY (bv_ok t.refs) vs
       | Rerr(Rraise v) => bv_ok t.refs v
       | _ => T) /\
      EVERY (bv_ok t.refs) env``,
  recInduct bvlSemTheory.evaluate_ind \\ REPEAT STRIP_TAC \\ fs [bvlSemTheory.evaluate_def]
  \\ SRW_TAC [] []
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [evaluate_ok_lemma]
  \\ SRW_TAC [] [] \\ REV_FULL_SIMP_TAC std_ss []
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [evaluate_ok_lemma]
  \\ SRW_TAC [] [] \\ REV_FULL_SIMP_TAC std_ss []
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [evaluate_ok_lemma]
  \\ SRW_TAC [] [] \\ REV_FULL_SIMP_TAC std_ss []
  \\ IMP_RES_TAC evaluate_SING \\ fs []
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [evaluate_ok_lemma]
  \\ SRW_TAC [] [] \\ REV_FULL_SIMP_TAC std_ss []
  \\ BasicProvers.EVERY_CASE_TAC \\ fs [evaluate_ok_lemma]
  \\ SRW_TAC [] [] \\ REV_FULL_SIMP_TAC std_ss []
  \\ TRY (fs [EVERY_EL] \\ NO_TAC)
  \\ IMP_RES_TAC evaluate_IMP_bv_ok
  \\ IMP_RES_TAC do_app_ok
  \\ REPEAT (Q.PAT_ASSUM `!xx.bb` (K ALL_TAC))
  \\ imp_res_tac do_app_err \\ fs[]
  \\ IMP_RES_TAC find_code_EVERY_IMP \\ fs [rich_listTheory.EVERY_REVERSE]
  \\ IMP_RES_TAC evaluate_IMP_bv_ok \\ fs [evaluate_ok_lemma]
  \\ fs [state_ok_def]);

(* semantics lemmas *)

val evaluate_MAP_Var = prove(
  ``!l env vs b s.
      EVERY isVar l /\ (get_vars (MAP destVar l) env = SOME vs) ==>
        (evaluate (MAP (Var o destVar) l,MAP (adjust_bv b) env,s) =
          (Rval (MAP (adjust_bv b) vs),s))``,
  Induct THEN1 (EVAL_TAC \\ SRW_TAC [] [])
  \\ Cases \\ fs [isVar_def,destVar_def,get_vars_def]
  \\ Cases_on `l` \\ fs [bviSemTheory.evaluate_def,get_vars_def,EL_MAP]
  \\ Cases_on `h` \\ fs [isVar_def,destVar_def]
  \\ REPEAT STRIP_TAC
  \\ Cases_on `n' < LENGTH env` \\ fs []
  \\ Cases_on `get_vars (MAP destVar t) env` \\ fs []
  \\ Q.PAT_ASSUM `!xx.bb` (MP_TAC o Q.SPEC `env`) \\ fs []
  \\ SRW_TAC [] [] \\ fs [EL_MAP]);

val evaluate_MAP_Var2 = prove(
  ``!args.
      bVarBound (LENGTH vs) args /\ EVERY isVar args ==>
      ?ts.
        bviSem$evaluate (MAP (Var o destVar) args,vs ++ env,s) = (Rval ts,s) /\
        evaluate (MAP (Var o destVar) args,vs,s) = (Rval ts,s)``,
  Induct \\ fs [MAP,bviSemTheory.evaluate_def] \\ Cases \\ fs [isVar_def]
  \\ Cases_on `args` \\ fs [MAP,bviSemTheory.evaluate_def,destVar_def,bVarBound_def]
  \\ REPEAT STRIP_TAC
  \\ `n < LENGTH vs + LENGTH env` by DECIDE_TAC \\ fs []
  \\ fs [rich_listTheory.EL_APPEND1]) |> SPEC_ALL;

val bEval_bVarBound = prove(
  ``!xs vs s env.
      bVarBound (LENGTH vs) xs ==>
      (bvlSem$evaluate (xs,vs ++ env,s) = evaluate (xs,vs,s))``,
  recInduct bvlSemTheory.evaluate_ind \\ REPEAT STRIP_TAC
  \\ fs [bvlSemTheory.evaluate_def,bVarBound_def]
  \\ TRY (BasicProvers.EVERY_CASE_TAC \\ fs [ADD1] \\ NO_TAC)
  THEN1 (`n < LENGTH env + LENGTH env'` by DECIDE_TAC
         \\ fs [rich_listTheory.EL_APPEND1])
  THEN1 (BasicProvers.EVERY_CASE_TAC \\ fs []
         \\ FIRST_X_ASSUM MATCH_MP_TAC \\ IMP_RES_TAC bvlPropsTheory.evaluate_IMP_LENGTH
         \\ fs [AC ADD_COMM ADD_ASSOC]));

val iEval_def = bviSemTheory.evaluate_def;

val iEval_bVarBound = prove(
  ``!(n:num) xs n vs (t:bvlSem$state) s env.
      bVarBound (LENGTH vs) xs /\ bEvery GoodHandleLet xs ==>
      (evaluate (FST (compile n xs),vs ++ env,s) =
       evaluate (FST (compile n xs),vs,s))``,
  recInduct (theorem "bVarBound_ind") \\ REPEAT STRIP_TAC
  \\ fs [iEval_def,bVarBound_def,compile_def] \\ SRW_TAC [] []
  \\ fs [bEvery_def,GoodHandleLet_def] \\ SRW_TAC [] []
  THEN1 (FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n1`,`vs`]) \\ fs []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n`,`vs`]) \\ fs []
    \\ IMP_RES_TAC compile_SING \\ SRW_TAC [] []
    \\ ONCE_REWRITE_TAC [bviPropsTheory.evaluate_CONS] \\ fs [])
  THEN1 (fs [rich_listTheory.EL_APPEND1])
  THEN1 (`F` by DECIDE_TAC)
  THEN1 (IMP_RES_TAC compile_SING \\ SRW_TAC [] []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n2`,`vs`]) \\ fs []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n1`,`vs`]) \\ fs []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n`,`vs`]) \\ fs []
    \\ fs [iEval_def])
  THEN1 (IMP_RES_TAC compile_SING \\ SRW_TAC [] [] \\ fs [iEval_def]
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n1`]) \\ fs []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n`,`vs`]) \\ fs []
    \\ REPEAT STRIP_TAC
    \\ Cases_on `evaluate (c1,vs,s)` \\ fs []
    \\ Cases_on `q` \\ fs []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`a ++ vs`]) \\ fs []
    \\ IMP_RES_TAC bviPropsTheory.evaluate_IMP_LENGTH \\ IMP_RES_TAC compile_LENGTH
    \\ REPEAT STRIP_TAC \\ POP_ASSUM MATCH_MP_TAC
    \\ fs [AC ADD_COMM ADD_ASSOC])
  \\ TRY (IMP_RES_TAC compile_SING \\ SRW_TAC [] []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n`,`vs`]) \\ fs []
    \\ fs [iEval_def] \\ NO_TAC)
  THEN1
   (FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n`,`vs`]) \\ fs []
    \\ Cases_on `op` \\ fs [compile_op_def,iEval_def,compile_int_thm]
    \\ BasicProvers.EVERY_CASE_TAC \\ fs [iEval_def,compile_int_thm])
  \\ fs [iEval_def]
  \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n2`]) \\ fs []
  \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`n`,`vs`]) \\ fs []
  \\ REPEAT STRIP_TAC \\ fs []
  \\ IMP_RES_TAC compile_SING \\ SRW_TAC [] []
  \\ fs [markerTheory.Abbrev_def] \\ SRW_TAC [] []
  \\ Cases_on `x1` \\ fs [GoodHandleLet_def,destLet_def]
  \\ SRW_TAC [] [] \\ fs [compile_def]
  \\ REV_FULL_SIMP_TAC std_ss [LET_DEF]
  \\ fs [iEval_def]
  \\ Q.PAT_ASSUM `!xx yy. bb = bbb` (ASSUME_TAC o Q.SPECL [`s`,`env`])
  \\ IMP_RES_TAC compile_Var_list \\ fs [] \\ SRW_TAC [] []
  \\ fs [bVarBound_def]
  \\ (evaluate_MAP_Var2 |> MP_TAC) \\ fs []
  \\ REPEAT STRIP_TAC \\ fs []
  \\ Cases_on `find_code (SOME (2 * n3 + 1)) ts s.code` \\ fs []
  \\ Cases_on `x` \\ fs [] \\ Cases_on `s.clock = 0` \\ fs []
  \\ Cases_on `evaluate ([r],q,dec_clock 1 s)` \\ fs []
  \\ Cases_on `q'` \\ fs []
  \\ Cases_on `e'` \\ fs []
  \\ ONCE_REWRITE_TAC [APPEND |> SPEC_ALL |> CONJUNCT2 |> GSYM]
  \\ FIRST_X_ASSUM MATCH_MP_TAC \\ fs [ADD1]);

(* compiler correctness *)

val compile_Var_list = prove(
  ``!l n. EVERY isVar l ==> (compile n l = (MAP (Var o destVar) l ,[],n))``,
  Induct \\ fs [EVERY_DEF,compile_def] \\ Cases \\ fs [isVar_def]
  \\ Cases_on `l` \\ fs [compile_def,destVar_def,LET_DEF]);

val compile_int_thm = prove(
  ``!i env s. evaluate ([compile_int i],env,s) = (Rval [Number i],s)``,
  STRIP_TAC \\ completeInduct_on `Num (ABS i)`
  \\ REPEAT STRIP_TAC \\ fs [PULL_FORALL] \\ POP_ASSUM (K ALL_TAC)
  \\ REVERSE (Cases_on `i`) \\ fs [] THEN1 EVAL_TAC
  \\ (ONCE_REWRITE_TAC [compile_int_def] \\ fs [LET_DEF]
    \\ SRW_TAC [] [] THEN1
     (`n <= 1073741823` by DECIDE_TAC
      \\ fs [evaluate_def,bviSemTheory.do_app_def,do_app_aux_def,small_enough_int_def])
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`&(n DIV 1000000000)`,`env`,`s`])
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC
    THEN1 (fs [integerTheory.INT_ABS_NUM,DIV_LT_X] \\ intLib.COOPER_TAC)
    \\ REPEAT STRIP_TAC \\ fs []
    \\ `n MOD 1000000000 < 1000000000` by fs [MOD_LESS]
    \\ `n MOD 1000000000 <= 1073741823` by DECIDE_TAC
    \\ fs [evaluate_def,bviSemTheory.do_app_def,do_app_aux_def,small_enough_int_def,bvlSemTheory.do_app_def]
    \\ fs [bvl_to_bvi_id]
    \\ STRIP_ASSUME_TAC
         (MATCH_MP DIVISION (DECIDE ``0 < 1000000000:num``) |> Q.SPEC `n`)
    \\ intLib.COOPER_TAC));

val bEvalOp_def = bvlSemTheory.do_app_def;
val iEvalOp_def = bviSemTheory.do_app_def;
val get_global_def = closSemTheory.get_global_def;

val v_to_list_adjust = Q.prove(
  `∀x. v_to_list (adjust_bv f x) = OPTION_MAP (MAP (adjust_bv f)) (v_to_list x)`,
  ho_match_mp_tac v_to_list_ind >>
  simp[v_to_list_def,adjust_bv_def] >> rw[] >>
  Cases_on`v_to_list x`>>fs[])

val do_app_adjust = prove(
  ``state_rel b2 s5 t2 /\
    (!i. op <> Const i) /\ (op <> Ref) /\ (op ≠ RefByte) ∧ (op ≠ RefArray) ∧
    (do_app op (REVERSE a) s5 = Rval (q,r)) /\ EVERY (bv_ok s5.refs) (REVERSE a) ==>
    ?t3. (do_app op (MAP (adjust_bv b2) (REVERSE a)) t2 =
           Rval (adjust_bv b2 q,t3)) /\
         state_rel b2 r t3``,
  SIMP_TAC std_ss [Once bEvalOp_def,iEvalOp_def,do_app_aux_def]
  \\ Cases_on `op` \\ fs []
  THEN1 (* Global *)
   (Cases_on `REVERSE a` \\ fs []
    \\ Cases_on `get_global n s5.globals` \\ fs []
    \\ Cases_on `x` \\ fs []
    \\ SRW_TAC [] [bEvalOp_def]
    \\ SIMP_TAC std_ss [Once bvi_to_bvl_def] \\ fs []
    \\ Q.EXISTS_TAC `t2` \\ fs []
    \\ fs [state_rel_def]
    \\ fs [get_global_def,EL_MAP,bvl_to_bvi_id])
  THEN1 (* SetGlobal *)
   (Cases_on `REVERSE a` \\ fs [] \\ Cases_on `t` \\ fs []
    \\ Cases_on `get_global n s5.globals` \\ fs []
    \\ Cases_on `x` \\ fs []
    \\ SRW_TAC [] [bEvalOp_def]
    \\ SIMP_TAC std_ss [Once bvi_to_bvl_def] \\ fs []
    \\ Q.EXISTS_TAC `t2 with globals := LUPDATE (SOME (adjust_bv b2 h)) n t2.globals`
    \\ fs [] \\ REVERSE (REPEAT STRIP_TAC)
    THEN1 (fs [state_rel_def,LUPDATE_SOME_MAP])
    \\ fs [state_rel_def]
    \\ fs [get_global_def,EL_MAP,adjust_bv_def,bvl_to_bvi_def,bvi_to_bvl_def]
    \\ fs [bviSemTheory.state_component_equality])
  THEN1 (* AllocGlobal *)
   (Cases_on `REVERSE a` \\ fs [] \\ SRW_TAC [] [bEvalOp_def,adjust_bv_def]
    \\ fs [state_rel_def,bvi_to_bvl_def,bvl_to_bvi_def,adjust_bv_def])
  THEN1 (* Cons *)
   (fs [bEvalOp_def]
    \\ SRW_TAC [] [adjust_bv_def,MEM_EQ_IMP_MAP_EQ,bvl_to_bvi_id]
    \\ SRW_TAC [] [adjust_bv_def,MEM_EQ_IMP_MAP_EQ,bvl_to_bvi_id])
  THEN1 (* El *)
   (BasicProvers.EVERY_CASE_TAC \\ fs [adjust_bv_def,bEvalOp_def]
    \\ every_case_tac >> fs[]
    \\ SRW_TAC [] []
    \\ fs [adjust_bv_def,MEM_EQ_IMP_MAP_EQ,bvl_to_bvi_id,
         bEvalOp_def,EL_MAP] \\ SRW_TAC [] [])
  THEN1 (* LengthBlock *)
   (BasicProvers.EVERY_CASE_TAC \\ fs [adjust_bv_def,bEvalOp_def]
    \\ SRW_TAC [] [] \\ fs[adjust_bv_def,bvl_to_bvi_id])
  THEN1 (* Length *) (
    every_case_tac >> fs[] >> rw[] >> fs[bEvalOp_def] >>
    every_case_tac >> fs[] >> rw[] >> fs[adjust_bv_def,bvl_to_bvi_id] >- (
      fs[state_rel_def,bvi_to_bvl_def] >> rw[] >>
      last_x_assum(qspec_then`n`mp_tac) >> rw[]) >>
    spose_not_then strip_assume_tac >> rw[] >>
    fs[bvi_to_bvl_def,state_rel_def] >>
    last_x_assum(qspec_then`n`mp_tac) >> rw[])
  THEN1 (* LengthByte *) (
    every_case_tac >> fs[] >> rw[] >> fs[bEvalOp_def] >>
    every_case_tac >> fs[] >> rw[] >> fs[adjust_bv_def,bvl_to_bvi_id] >- (
      fs[state_rel_def,bvi_to_bvl_def] >> rw[] >>
      last_x_assum(qspec_then`n`mp_tac) >> rw[]) >>
    spose_not_then strip_assume_tac >> rw[] >>
    fs[bvi_to_bvl_def,state_rel_def] >>
    last_x_assum(qspec_then`n`mp_tac) >> rw[])
  (*
  THEN1 (* RefByte *) (
    Cases_on`REVERSE a`>>fs[]>>
    Cases_on`t`>>fs[]>>
    Cases_on`h'`>>fs[]>>
    Cases_on`h`>>fs[]>>
    Cases_on`t'`>>fs[]>>
    simp[bEvalOp_def,adjust_bv_def] >>
    IF_CASES_TAC >> simp[] >>
    strip_tac >> rpt var_eq_tac >>
    simp[adjust_bv_def,bvl_to_bvi_with_refs,bvl_to_bvi_id] >>
    simp[bvi_to_bvl_def] >>
    conj_asm1_tac >- cheat >>
    fs[state_rel_def] >>
    conj_tac >- (
      simp[INJ_INSERT] >>
      cheat ) >>
    simp[FLOOKUP_UPDATE] >>
    rw[] >> fs[] >>
    BasicProvers.CASE_TAC >>
    `k ∈ FDOM s5.refs` by fs[FLOOKUP_DEF] >>
    `b2 k ∈ FDOM t2.refs` by fs[INJ_DEF] >>
    cheat (* LEAST_NOT_IN_FDOM *))
  THEN1 (* RefArray *) (
    Cases_on`REVERSE a`>>fs[]>>
    Cases_on`t`>>fs[]>>
    Cases_on`h`>>fs[]>>
    Cases_on`t'`>>fs[]>>
    simp[bEvalOp_def,adjust_bv_def] >>
    IF_CASES_TAC >> simp[] >>
    strip_tac >> rpt var_eq_tac >>
    simp[adjust_bv_def,bvl_to_bvi_with_refs,bvl_to_bvi_id] >>
    simp[bvi_to_bvl_def] >>
    conj_asm1_tac >- cheat >>
    fs[state_rel_def] >>
    conj_tac >- (
      simp[INJ_INSERT] >>
      cheat ) >>
    simp[FLOOKUP_UPDATE] >>
    rw[] >> fs[map_replicate] >>
    BasicProvers.CASE_TAC >>
    `k ∈ FDOM s5.refs` by fs[FLOOKUP_DEF] >>
    `b2 k ∈ FDOM t2.refs` by fs[INJ_DEF] >>
    cheat (* LEAST_NOT_IN_FDOM *))
  *)
  THEN1 (* DerefByte *) (
    Cases_on`REVERSE a`>>fs[]>>
    Cases_on`t`>>fs[]>>
    Cases_on`h'`>>fs[]>>
    Cases_on`h`>>fs[]>>
    Cases_on`t'`>>fs[]>>
    simp[bEvalOp_def,adjust_bv_def] >>
    simp[Once bvi_to_bvl_def] >> rw[] >>
    every_case_tac >> fs[] >>rw[] >> rw[adjust_bv_def,bvl_to_bvi_id] >>
    fs[state_rel_def] >>
    last_x_assum(qspec_then`n`mp_tac) >> simp[] >>
    spose_not_then strip_assume_tac >> fs[])
  THEN1 (* UpdateByte *) (
    Cases_on`REVERSE a`>>fs[]>>
    Cases_on`t`>>fs[]>>
    Cases_on`t'`>>fs[]>>
    Cases_on`h''`>>fs[]>>
    Cases_on`h'`>>fs[]>>
    Cases_on`h`>>fs[]>>
    Cases_on`t`>>fs[]>>
    simp[bEvalOp_def,adjust_bv_def] >>
    simp[Once bvi_to_bvl_def] >> rw[] >>
    every_case_tac >> fs[] >>rw[] >>
    rw[adjust_bv_def,bvl_to_bvi_with_refs,bvl_to_bvi_id] >>
    fs[state_rel_def] >>
    TRY (
      last_x_assum(qspec_then`n`mp_tac) >> simp[] >>
      spose_not_then strip_assume_tac >> rpt var_eq_tac >> fs[] >>
      NO_TAC) >>
    simp[bvi_to_bvl_def] >>
    conj_asm1_tac >- (
      simp[INJ_INSERT] >>
      conj_tac >- (
        rator_x_assum`INJ`mp_tac >>
        simp[INJ_DEF] ) >>
      `n ∈ FDOM s5.refs` by fs[FLOOKUP_DEF] >>
      metis_tac[INJ_DEF]) >>
    simp[FLOOKUP_UPDATE] >>
    rw[] >- (
      last_x_assum(qspec_then`k`mp_tac) >> simp[] ) >>
    BasicProvers.CASE_TAC >>
    `k ∈ FDOM s5.refs ∧ n ∈ FDOM s5.refs` by fs[FLOOKUP_DEF] >>
    metis_tac[INJ_DEF])
  THEN1 (* FromList *) (
    Cases_on`REVERSE a`>>fs[]>>
    Cases_on`t`>>fs[] >>
    simp[bEvalOp_def,v_to_list_adjust] >>
    Cases_on`v_to_list h`>>simp[] >> strip_tac >>
    rpt var_eq_tac >> simp[bvl_to_bvi_id,adjust_bv_def] >>
    srw_tac[ETA_ss][])
  THEN1 (* TagLenEq *) (
    every_case_tac >> fs[bEvalOp_def,adjust_bv_def] >>
    rw[] >> rw[bvl_to_bvi_id])
  THEN1 (* TagEq *)
    (BasicProvers.EVERY_CASE_TAC \\ fs [adjust_bv_def,bEvalOp_def]
     \\ SRW_TAC [] []
     \\ simp[bvl_to_bvi_id])
  THEN1 (* BlockCmp *) (
    every_case_tac >> fs[bEvalOp_def,adjust_bv_def] >>
    rw[] >> simp[bvl_to_bvi_id])
  THEN1 (* IsBlock *)
   (BasicProvers.EVERY_CASE_TAC \\ fs [adjust_bv_def,bEvalOp_def]
    \\ SRW_TAC [] []
    \\ simp[bvl_to_bvi_id])
  THEN1 (* Deref *)
   (Cases_on `REVERSE a` \\ fs []
    \\ Cases_on `t` \\ fs []
    \\ Cases_on `h'` \\ fs []
    \\ Cases_on `h` \\ fs []
    \\ Cases_on `t'` \\ fs []
    \\ Cases_on `FLOOKUP s5.refs n` \\ fs []
    \\ Cases_on `x` \\ fs []
    \\ REPEAT STRIP_TAC \\ SRW_TAC [] [adjust_bv_def]
    \\ fs [bEvalOp_def] \\ SIMP_TAC std_ss [Once bvi_to_bvl_def] \\ fs []
    \\ Q.EXISTS_TAC `t2` \\ fs []
    \\ `FLOOKUP t2.refs (b2 n) = SOME(ValueArray(MAP (adjust_bv b2) l))` by (
        fs [state_rel_def] >>
        last_x_assum(qspec_then`n`mp_tac) >>
        simp[] )
    \\ simp[]
    \\ IF_CASES_TAC >> fs[] >> fs[]
    \\ `Num i < LENGTH l` by METIS_TAC[integerTheory.INT_OF_NUM,integerTheory.INT_LT]
    \\ simp[EL_MAP,bvl_to_bvi_id])
  THEN1 (* Update *)
   (Cases_on `REVERSE a` \\ fs []
    \\ Cases_on `t` \\ fs []
    \\ Cases_on `t'` \\ fs []
    \\ Cases_on `h'` \\ fs []
    \\ Cases_on `h` \\ fs []
    \\ Cases_on `t` \\ fs []
    \\ Cases_on `FLOOKUP s5.refs n` \\ fs []
    \\ Cases_on `x` \\ fs []
    \\ REPEAT STRIP_TAC \\ SRW_TAC [] [adjust_bv_def]
    \\ fs [bEvalOp_def] \\ SIMP_TAC std_ss [Once bvi_to_bvl_def] \\ fs []
    \\ `FLOOKUP t2.refs (b2 n) =
        SOME (ValueArray (MAP (adjust_bv b2) l))` by ALL_TAC THEN1
     (fs [state_rel_def,bvl_to_bvi_def,bvi_to_bvl_def]
      \\ Q.PAT_ASSUM `!k.bbb` (K ALL_TAC)
      \\ Q.PAT_ASSUM `!k.bbb` (MP_TAC o Q.SPEC `n`) \\ fs [])
    \\ simp[]
    \\ IF_CASES_TAC >> fs[] >> fs[]
    \\ rpt var_eq_tac \\ simp[]
    \\ simp[bvl_to_bvi_with_refs,bvl_to_bvi_id]
    \\ fs [state_rel_def,bvl_to_bvi_def,bvi_to_bvl_def]
    \\ fs [FLOOKUP_FAPPLY]
    \\ REPEAT STRIP_TAC
    THEN1 fs [FLOOKUP_DEF,IN_INSERT_EQ]
    \\ Cases_on `k = n` \\ fs [MAP_LUPDATE]
    \\ Cases_on `FLOOKUP s5.refs k = NONE` \\ fs []
    \\ `b2 k <> b2 n` by ALL_TAC \\ fs []
    \\ fs [INJ_DEF,FLOOKUP_DEF]
    \\ REPEAT STRIP_TAC \\ RES_TAC)
  THEN1 (* Label *)
   (BasicProvers.EVERY_CASE_TAC \\ fs [bEvalOp_def,bvl_to_bvi_id]
    \\ SRW_TAC [] [] \\ fs [adjust_bv_def])
  THEN1 (* FFI *) (
    Cases_on`REVERSE a`>>fs[]>>
    Cases_on`h`>>fs[]>>
    Cases_on`t`>>fs[]>>
    simp[bEvalOp_def,adjust_bv_def] >>
    rw[] >>
    qmatch_assum_rename_tac`bv_ok s5.refs (RefPtr k)` >>
    Cases_on`FLOOKUP s5.refs k`>>fs[]>>
    Cases_on`x`>>fs[]>>
    simp[Once bvi_to_bvl_def] >>
    `FLOOKUP t2.refs (b2 k) = SOME (ByteArray l)` by (
      fs[state_rel_def] >>
      last_x_assum(qspec_then`k`mp_tac) >> simp[] ) >>
    simp[] >>
    simp[Once bvi_to_bvl_def] >>
    `s5.io = t2.io` by fs[state_rel_def] >>
    BasicProvers.CASE_TAC >> fs[] >>
    every_case_tac >> fs[] >> rw[] >>
    simp[bvl_to_bvi_with_refs,bvl_to_bvi_with_io,bvl_to_bvi_id] >>
    simp[bvi_to_bvl_def] >>
    fs[state_rel_def] >>
    conj_tac >- (
      fs[FLOOKUP_DEF] >>
      simp[IN_INSERT_EQ] ) >>
    simp[FLOOKUP_FAPPLY] >> rw[] >>
    BasicProvers.CASE_TAC >>
    fs[FLOOKUP_DEF] >>
    METIS_TAC[INJ_DEF])
  THEN1 (* Equal *) (
    simp[bEvalOp_def] >>
    Cases_on`REVERSE a`>>fs[] >>
    Cases_on`t`>>fs[] >>
    Cases_on`t'`>>fs[] >>
    Cases_on`h'`>>fs[] >>
    Cases_on`h`>>fs[] >>
    strip_tac >> rpt var_eq_tac >>
    simp[adjust_bv_def,bvl_to_bvi_id] >>
    fs[state_rel_def,bv_ok_def] >>
    METIS_TAC[INJ_DEF] )
  \\ (* Add, Sub, Mult, Div, Mod, Less, ... *)
   (REPEAT STRIP_TAC
    \\ Cases_on `REVERSE a` \\ fs [] \\ Cases_on `t` \\ fs []
    \\ Cases_on `h'` \\ fs [] \\ Cases_on `h` \\ fs []
    \\ Cases_on `t'` \\ fs [] \\ SRW_TAC [] []
    \\ fs [bEvalOp_def,adjust_bv_def,bvl_to_bvi_id]
    \\ every_case_tac >> fs[bvl_to_bvi_id] >> rw[]
    \\ EVAL_TAC ));

val bEval_def = bvlSemTheory.evaluate_def;

val compile_correct = Q.prove(
  `!xs env s1 n res s2 t1 n2 ys aux b1.
     (evaluate (xs,env,s1) = (res,s2)) /\ res <> Rerr(Rabort Rtype_error) /\
     (compile n xs = (ys,aux,n2)) /\
     state_rel b1 s1 t1 /\
     state_ok s1 /\ EVERY (bv_ok s1.refs) env /\
     aux_code_installed aux t1.code /\
     bEvery GoodHandleLet xs ==>
     ?t2 b2 c.
        (evaluate (ys,MAP (adjust_bv b2) env,inc_clock c t1) =
           (map_result (MAP (adjust_bv b2)) (adjust_bv b2) res,t2)) /\
        state_rel b2 s2 t2 /\
        (MAP (adjust_bv b1) env = MAP (adjust_bv b2) env) /\
        (!a. a IN FDOM s1.refs ==> (b1 a = b2 a))``,
  SIMP_TAC std_ss []
  \\ recInduct bvlSemTheory.evaluate_ind \\ REPEAT STRIP_TAC
  \\ fs [bEval_def,compile_def,iEval_def,bEvery_def,GoodHandleLet_def]
  THEN1 (* NIL *)
   (SRW_TAC [] [iEval_def]
    \\ Q.LIST_EXISTS_TAC [`b1`,`0`] \\ fs [inc_clock_ZERO])
  THEN1 (* CONS *)
   (`?c1 aux1 n1. compile n [x] = (c1,aux1,n1)` by METIS_TAC [PAIR]
    \\ `?c2 aux2 n2. compile n1 (y::xs) = (c2,aux2,n2)` by METIS_TAC [PAIR]
    \\ fs [LET_DEF] \\ SRW_TAC [] [] \\ fs [PULL_FORALL]
    \\ `?res5 s5. evaluate ([x],env,s) = (res5,s5)` by METIS_TAC [PAIR]
    \\ `?res6 s6. evaluate (y::xs,env,s5) = (res6,s6)` by METIS_TAC [PAIR]
    \\ IMP_RES_TAC evaluate_ok \\ fs []
    \\ IMP_RES_TAC aux_code_installed_APPEND \\ SRW_TAC [] []
    \\ fs [] \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`) \\ fs []
    \\ REVERSE (Cases_on `res5`) \\ fs [] \\ REPEAT STRIP_TAC
    \\ POP_ASSUM (MP_TAC o Q.SPECL [`t1`,`b1`]) \\ fs []
    \\ rpt var_eq_tac
    \\ TRY (discharge_hyps >- (spose_not_then strip_assume_tac >> fs[]))
    \\ TRY (REPEAT STRIP_TAC \\ IMP_RES_TAC compile_LENGTH
      \\ `?d. c1 = [d]` by (Cases_on `c1` \\ fs [LENGTH_NIL])
      \\ SIMP_TAC std_ss [Once bviPropsTheory.evaluate_CONS] \\ fs []
      \\ SIMP_TAC std_ss [Once bviPropsTheory.evaluate_CONS] \\ fs [GSYM PULL_FORALL]
      \\ Q.LIST_EXISTS_TAC [`t2`,`b2`,`c`] \\ fs [] \\ NO_TAC)
    \\ REPEAT STRIP_TAC
    \\ Q.PAT_ASSUM `!nn mm. bbb` (MP_TAC o Q.SPEC `n1`) \\ fs []
    \\ `res6 <> Rerr(Rabort Rtype_error)` by (REPEAT STRIP_TAC \\ fs []) \\ fs []
    \\ REPEAT STRIP_TAC
    \\ IMP_RES_TAC compile_LENGTH
    \\ `?d. c1 = [d]` by (Cases_on `c1` \\ fs [LENGTH_NIL]) \\ fs []
    \\ `aux_code_installed aux2 t2.code` by
     (fs [GSYM PULL_FORALL]
      \\ IMP_RES_TAC evaluate_code_const \\ fs [inc_clock_def])
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`t2`,`b2`]) \\ fs []
    \\ `s2 = s6` by (BasicProvers.EVERY_CASE_TAC \\ fs [])
    \\ REPEAT STRIP_TAC \\ fs [GSYM PULL_FORALL]
    \\ Q.MATCH_ASSUM_RENAME_TAC
        `evaluate (c2,MAP (adjust_bv b3) env,inc_clock c4 t2) =
           (map_result (MAP (adjust_bv b3)) (adjust_bv b3) res6,t3)`
    \\ IMP_RES_TAC evaluate_inv_clock
    \\ fs [inc_clock_ADD]
    \\ ONCE_REWRITE_TAC [bviPropsTheory.evaluate_CONS] \\ fs []
    \\ REV_FULL_SIMP_TAC std_ss []
    \\ Q.LIST_EXISTS_TAC [`t3`,`b3`,`c4 + c`] \\ fs []
    \\ Cases_on `res6` \\ fs []
    \\ Q.PAT_ASSUM `xx = res` (ASSUME_TAC o GSYM) \\ fs []
    \\ IMP_RES_TAC evaluate_refs_SUBSET \\ fs [SUBSET_DEF]
    \\ IMP_RES_TAC bvlPropsTheory.evaluate_SING \\ fs []
    \\ MATCH_MP_TAC bv_ok_IMP_adjust_bv_eq \\ fs [])
  THEN1 (* Var *)
   (Cases_on `n < LENGTH env` \\ fs [] \\ SRW_TAC [] []
    \\ fs [iEval_def] \\ Q.LIST_EXISTS_TAC [`b1`,`0`]
    \\ fs [inc_clock_ZERO,EL_MAP])
  THEN1 (* If *)
   (Q.ABBREV_TAC `n4 = n2` \\ POP_ASSUM (K ALL_TAC)
    \\ `?c1 aux1 n1. compile n [x1] = (c1,aux1,n1)` by METIS_TAC [PAIR]
    \\ `?c2 aux2 n2. compile n1 [x2] = (c2,aux2,n2)` by METIS_TAC [PAIR]
    \\ `?c3 aux3 n3. compile n2 [x3] = (c3,aux3,n3)` by METIS_TAC [PAIR]
    \\ fs [LET_DEF] \\ SRW_TAC [] [] \\ fs [PULL_FORALL]
    \\ `?res5 s5. evaluate ([x1],env,s) = (res5,s5)` by METIS_TAC [PAIR]
    \\ IMP_RES_TAC evaluate_ok \\ fs []
    \\ IMP_RES_TAC aux_code_installed_APPEND \\ SRW_TAC [] []
    \\ fs [] \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`) \\ fs []
    \\ REVERSE (Cases_on `res5`) \\ fs [] \\ REPEAT STRIP_TAC
    \\ POP_ASSUM (MP_TAC o Q.SPECL [`t1`,`b1`]) \\ fs []
    \\ IMP_RES_TAC aux_code_installed_APPEND \\ fs [GSYM PULL_FORALL]
    \\ TRY (
      discharge_hyps >- (rpt strip_tac >> fs[])
      \\ REPEAT STRIP_TAC \\ IMP_RES_TAC compile_LENGTH
      \\ `?d. c1 = [d]` by (Cases_on `c1` \\ fs [LENGTH_NIL])
      \\ SIMP_TAC std_ss [Once iEval_def] \\ fs []
      \\ Q.LIST_EXISTS_TAC [`t2`,`b2`,`c`] \\ fs []
      \\ rw[] \\ NO_TAC)
    \\ REPEAT STRIP_TAC
    \\ IMP_RES_TAC bvlPropsTheory.evaluate_SING \\ fs []
    \\ Cases_on `d1 = Boolv T` \\ fs []
    THEN1
     (IMP_RES_TAC compile_LENGTH
      \\ `?d. c1 = [d]` by (Cases_on `c1` \\ fs [LENGTH_NIL])
      \\ SIMP_TAC std_ss [Once iEval_def] \\ fs []
      \\ `?d2. c2 = [d2]` by (Cases_on `c2` \\ fs [LENGTH_NIL]) \\ fs []
      \\ Q.PAT_ASSUM `!nn mm. bbb` (MP_TAC o Q.SPEC `n1`) \\ fs []
      \\ `aux_code_installed aux2 t2.code` by
       (fs [GSYM PULL_FORALL]
        \\ IMP_RES_TAC evaluate_code_const \\ fs [inc_clock_def])
      \\ REPEAT STRIP_TAC
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`t2`,`b2`]) \\ fs []
      \\ REPEAT STRIP_TAC \\ fs [GSYM PULL_FORALL]
      \\ IMP_RES_TAC evaluate_inv_clock \\ fs [inc_clock_ADD]
      \\ REV_FULL_SIMP_TAC std_ss []
      \\ Q.LIST_EXISTS_TAC [`t2'`,`b2'`,`c' + c`] \\ fs []
      \\ fs [adjust_bv_def]
      \\ IMP_RES_TAC evaluate_refs_SUBSET \\ fs [SUBSET_DEF])
    \\ Cases_on `d1 = Boolv F` \\ fs []
    THEN1
     (IMP_RES_TAC compile_LENGTH
      \\ `?d. c1 = [d]` by (Cases_on `c1` \\ fs [LENGTH_NIL])
      \\ SIMP_TAC std_ss [Once iEval_def] \\ fs []
      \\ `?d3. c3 = [d3]` by (Cases_on `c3` \\ fs [LENGTH_NIL]) \\ fs []
      \\ Q.PAT_ASSUM `!nn mm. bbb` (MP_TAC o Q.SPEC `n2`) \\ fs []
      \\ `aux_code_installed aux3 t2.code` by
       (fs [GSYM PULL_FORALL]
        \\ IMP_RES_TAC evaluate_code_const \\ fs [inc_clock_def])
      \\ REPEAT STRIP_TAC
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`t2`,`b2`]) \\ fs []
      \\ REPEAT STRIP_TAC \\ fs [GSYM PULL_FORALL]
      \\ IMP_RES_TAC evaluate_inv_clock \\ fs [inc_clock_ADD]
      \\ REV_FULL_SIMP_TAC std_ss []
      \\ Q.LIST_EXISTS_TAC [`t2'`,`b2'`,`c' + c`] \\ fs []
      \\ fs [adjust_bv_def]
      \\ IMP_RES_TAC evaluate_refs_SUBSET \\ fs [SUBSET_DEF]))
  THEN1 (* Let *)
   (`?c1 aux1 n1. compile n xs = (c1,aux1,n1)` by METIS_TAC [PAIR]
    \\ `?c2 aux2 n2. compile n1 [x2] = (c2,aux2,n2)` by METIS_TAC [PAIR]
    \\ fs [LET_DEF] \\ SRW_TAC [] [] \\ fs [PULL_FORALL]
    \\ `?res5 s5. evaluate (xs,env,s) = (res5,s5)` by METIS_TAC [PAIR]
    \\ IMP_RES_TAC evaluate_ok \\ fs []
    \\ IMP_RES_TAC aux_code_installed_APPEND \\ SRW_TAC [] []
    \\ fs [] \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`) \\ fs []
    \\ REVERSE (Cases_on `res5`) \\ fs [] \\ REPEAT STRIP_TAC
    \\ POP_ASSUM (MP_TAC o Q.SPECL [`t1`,`b1`]) \\ fs []
    \\ TRY (
      discharge_hyps >- (rpt strip_tac >> fs[])
      \\ REPEAT STRIP_TAC \\ IMP_RES_TAC compile_LENGTH
      \\ `?d. c2 = [d]` by (Cases_on `c2` \\ fs [LENGTH_NIL])
      \\ SIMP_TAC std_ss [Once iEval_def] \\ fs []
      \\ Q.LIST_EXISTS_TAC [`t2`,`b2`,`c`] \\ fs []
      \\ rw [] \\ NO_TAC)
    \\ REPEAT STRIP_TAC
    \\ Q.MATCH_ASSUM_RENAME_TAC `evaluate ([x2],a ++ env,s5) = (res6,s6)`
    \\ Q.PAT_ASSUM `!nn mm. bbb` (MP_TAC o Q.SPEC `n1`) \\ fs []
    \\ REPEAT STRIP_TAC
    \\ IMP_RES_TAC compile_LENGTH
    \\ `?d. c2 = [d]` by (Cases_on `c2` \\ fs [LENGTH_NIL]) \\ fs []
    \\ `aux_code_installed aux2 t2.code` by
     (fs [GSYM PULL_FORALL]
      \\ IMP_RES_TAC evaluate_code_const \\ fs [inc_clock_def])
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`t2`,`b2`]) \\ fs []
    \\ REPEAT STRIP_TAC \\ fs [GSYM PULL_FORALL]
    \\ Q.MATCH_ASSUM_RENAME_TAC
        `evaluate ([d],MAP (adjust_bv b3) a ++
                    MAP (adjust_bv b3) env,inc_clock c4 t2) =
           (map_result (MAP (adjust_bv b3)) (adjust_bv b3) res6,t3)`
    \\ IMP_RES_TAC evaluate_inv_clock
    \\ fs [inc_clock_ADD]
    \\ ONCE_REWRITE_TAC [iEval_def] \\ fs []
    \\ fs [MAP_APPEND_MAP_EQ]
    \\ REV_FULL_SIMP_TAC std_ss []
    \\ Q.LIST_EXISTS_TAC [`t3`,`b3`,`c4 + c`] \\ fs []
    \\ IMP_RES_TAC evaluate_refs_SUBSET \\ fs [SUBSET_DEF])
  THEN1 (* Raise *)
   (`?c1 aux1 n1. compile n [x1] = (c1,aux1,n1)` by METIS_TAC [PAIR]
    \\ fs [LET_DEF] \\ SRW_TAC [] [] \\ fs [PULL_FORALL]
    \\ IMP_RES_TAC compile_LENGTH
    \\ `?d. c1 = [d]` by (Cases_on `c1` \\ fs [LENGTH_NIL]) \\ fs []
    \\ SRW_TAC [] []
    \\ `?res5 s5. evaluate ([x1],env,s) = (res5,s5)` by METIS_TAC [PAIR]
    \\ REVERSE (Cases_on `res5`) \\ fs [] \\ REPEAT STRIP_TAC
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`) \\ fs []
    \\ TRY (SRW_TAC [] [] \\ fs []
      \\ REPEAT STRIP_TAC \\ RES_TAC
      \\ Q.LIST_EXISTS_TAC [`t2`,`b2`,`c`] \\ fs []
      \\ SIMP_TAC std_ss [Once bviPropsTheory.evaluate_CONS] \\ fs []
      \\ fs [iEval_def] \\ NO_TAC)
    \\ REPEAT STRIP_TAC \\ RES_TAC \\ fs [iEval_def]
    \\ Q.LIST_EXISTS_TAC [`t2`,`b2`,`c`] \\ fs [] \\ SRW_TAC [] []
    \\ IMP_RES_TAC bvlPropsTheory.evaluate_SING \\ SRW_TAC [] [])
  THEN1 (* Handle *)
   (Cases_on `x1` \\ fs [GoodHandleLet_def,destLet_def] \\ fs [LET_DEF]
    \\ fs [compile_Var_list]
    \\ `?c2 aux2 n2. compile n [e] = (c2,aux2,n2)` by METIS_TAC [PAIR]
    \\ `?c3 aux3 n3. compile n2' [x2] = (c3,aux3,n3)` by METIS_TAC [PAIR]
    \\ fs [] \\ SRW_TAC [] [] \\ fs [bEval_def]
    \\ MP_TAC (Q.SPEC `l` evaluate_Var_list |> Q.INST [`s`|->`s1`]) \\ fs []
    \\ STRIP_TAC \\ fs []
    \\ `evaluate ([e],vs ++ env,s1) = evaluate ([e],vs,s1)` by ALL_TAC
    THEN1 (MATCH_MP_TAC bEval_bVarBound \\ fs [])
    \\ fs [] \\ POP_ASSUM (K ALL_TAC)
    \\ Cases_on `evaluate ([e],vs,s1)` \\ fs []
    \\ `?d2. c2 = [d2]` by
           (IMP_RES_TAC compile_LENGTH \\ Cases_on `c2` \\ fs [LENGTH_NIL])
    \\ `?d3. c3 = [d3]` by
           (IMP_RES_TAC compile_LENGTH \\ Cases_on `c3` \\ fs [LENGTH_NIL])
    \\ fs [] \\ NTAC 2 (POP_ASSUM (K ALL_TAC))
    \\ (Cases_on `q`) \\ fs []
    THEN1 (* Result case *)
     (SRW_TAC [] [] \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`)
      \\ fs [compile_def,compile_Var_list,LET_DEF]
      \\ STRIP_TAC \\ POP_ASSUM (MP_TAC o Q.SPECL [`t1`,`b1`])
      \\ fs []
      \\ IMP_RES_TAC aux_code_installed_APPEND \\ fs []
      \\ IMP_RES_TAC aux_code_installed_APPEND \\ fs []
      \\ REPEAT STRIP_TAC
      \\ fs [] \\ SRW_TAC [] []
      \\ fs [aux_code_installed_def,iEval_def,find_code_def]
      \\ IMP_RES_TAC (GEN_ALL evaluate_MAP_Var) \\ fs []
      \\ `evaluate ([d2],MAP (adjust_bv b2) vs ++ MAP (adjust_bv b2) env,
            inc_clock c t1) =
          evaluate ([d2],MAP (adjust_bv b2) vs,inc_clock c t1)` by ALL_TAC THEN1
       ((iEval_bVarBound |> SPEC_ALL |> Q.INST [`xs`|->`[e]`,
           `vs`|->`MAP (adjust_bv b2) vs`]
           |> Q.GENL [`env`,`s`] |> MP_TAC) \\ fs [bEvery_def]
        \\ REPEAT STRIP_TAC \\ fs [])
      \\ fs [] \\ POP_ASSUM (K ALL_TAC)
      \\ SIMP_TAC std_ss [Once inc_clock_def] \\ fs []
      \\ SIMP_TAC std_ss [Once inc_clock_def] \\ fs []
      \\ Q.LIST_EXISTS_TAC [`t2`,`b2`,`c + 1`] \\ fs []
      \\ `dec_clock 1 (inc_clock (c + 1) t1) = inc_clock c t1` by
        (EVAL_TAC \\ fs [bviSemTheory.state_component_equality] \\ DECIDE_TAC) \\ fs [])
    \\ (Cases_on`e'`) \\ fs[]
    THEN1 (* Raise case *)
     (SRW_TAC [] [] \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`)
      \\ fs [compile_def,compile_Var_list,LET_DEF]
      \\ STRIP_TAC \\ POP_ASSUM (MP_TAC o Q.SPECL [`t1`,`b1`])
      \\ fs []
      \\ IMP_RES_TAC aux_code_installed_APPEND \\ fs []
      \\ IMP_RES_TAC aux_code_installed_APPEND \\ fs []
      \\ REPEAT STRIP_TAC
      \\ fs [] \\ SRW_TAC [] []
      \\ fs [aux_code_installed_def,iEval_def,find_code_def]
      \\ IMP_RES_TAC (GEN_ALL evaluate_MAP_Var) \\ fs []
      \\ `evaluate ([d2],MAP (adjust_bv b2) vs ++ MAP (adjust_bv b2) env,
            inc_clock c t1) =
          evaluate ([d2],MAP (adjust_bv b2) vs,inc_clock c t1)` by ALL_TAC THEN1
       ((iEval_bVarBound |> SPEC_ALL |> Q.INST [`xs`|->`[e]`,
           `vs`|->`MAP (adjust_bv b2) vs`]
           |> Q.GENL [`env`,`s`] |> MP_TAC) \\ fs [bEvery_def]
        \\ REPEAT STRIP_TAC \\ fs [])
      \\ fs [] \\ POP_ASSUM (K ALL_TAC)
      \\ SIMP_TAC std_ss [Once inc_clock_def] \\ fs []
      \\ SIMP_TAC std_ss [Once inc_clock_def] \\ fs []
      \\ Q.PAT_ASSUM `!nn mm nn1. bbb` (MP_TAC o Q.SPEC `n2'`) \\ fs []
      \\ REPEAT STRIP_TAC
      \\ POP_ASSUM (MP_TAC o Q.SPECL [`t2`,`b2`]) \\ fs []
      \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
       (IMP_RES_TAC evaluate_ok \\ fs [] \\ REV_FULL_SIMP_TAC std_ss []
        \\ IMP_RES_TAC aux_code_installed_APPEND \\ fs []
        \\ IMP_RES_TAC aux_code_installed_APPEND \\ fs []
        \\ IMP_RES_TAC evaluate_code_const \\ fs [inc_clock_def]
        \\ `EVERY (bv_ok r.refs) env` by ALL_TAC \\ fs []
        \\ fs [EVERY_MEM] \\ REPEAT STRIP_TAC \\ RES_TAC
        \\ IMP_RES_TAC evaluate_refs_SUBSET
        \\ IMP_RES_TAC bv_ok_SUBSET_IMP)
      \\ REPEAT STRIP_TAC
      \\ Q.LIST_EXISTS_TAC [`t2'`,`b2'`,`c' + c + 1`] \\ fs []
      \\ `dec_clock 1 (inc_clock (c' + c + 1) t1) = inc_clock (c' + c) t1` by
        (EVAL_TAC \\ fs [bviSemTheory.state_component_equality] \\ DECIDE_TAC) \\ fs []
      \\ IMP_RES_TAC evaluate_inv_clock \\ fs [inc_clock_ADD]
      \\ `MAP (adjust_bv b2) vs = MAP (adjust_bv b2') vs` by ALL_TAC THEN1
       (fs [MEM_EQ_IMP_MAP_EQ] \\ REPEAT STRIP_TAC
        \\ MATCH_MP_TAC (bv_ok_IMP_adjust_bv_eq |> GEN_ALL)
        \\ Q.EXISTS_TAC `r` \\ fs []
        \\ IMP_RES_TAC evaluate_ok \\ fs [] \\ REV_FULL_SIMP_TAC std_ss []
        \\ fs [EVERY_MEM] \\ RES_TAC)
      \\ fs [] \\ IMP_RES_TAC evaluate_refs_SUBSET \\ fs [SUBSET_DEF])
    THEN1 (* abort case *)
     (SRW_TAC [] [] \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`)
      \\ fs [compile_def,compile_Var_list,LET_DEF]
      \\ STRIP_TAC \\ POP_ASSUM (MP_TAC o Q.SPECL [`t1`,`b1`])
      \\ fs []
      \\ IMP_RES_TAC aux_code_installed_APPEND \\ fs []
      \\ IMP_RES_TAC aux_code_installed_APPEND \\ fs []
      \\ REPEAT STRIP_TAC
      \\ fs [] \\ SRW_TAC [] []
      \\ fs [aux_code_installed_def,iEval_def,find_code_def]
      \\ IMP_RES_TAC (GEN_ALL evaluate_MAP_Var) \\ fs []
      \\ `evaluate ([d2],MAP (adjust_bv b2) vs ++ MAP (adjust_bv b2) env,
            inc_clock c t1) =
          evaluate ([d2],MAP (adjust_bv b2) vs,inc_clock c t1)` by ALL_TAC THEN1
       ((iEval_bVarBound |> SPEC_ALL |> Q.INST [`xs`|->`[e]`,
           `vs`|->`MAP (adjust_bv b2) vs`]
           |> Q.GENL [`env`,`s`] |> MP_TAC) \\ fs [bEvery_def]
        \\ REPEAT STRIP_TAC \\ fs [])
      \\ fs [] \\ POP_ASSUM (K ALL_TAC)
      \\ SIMP_TAC std_ss [Once inc_clock_def] \\ fs []
      \\ SIMP_TAC std_ss [Once inc_clock_def] \\ fs []
      \\ Q.LIST_EXISTS_TAC [`t2`,`b2`,`c + 1`] \\ fs []
      \\ `dec_clock 1 (inc_clock (c + 1) t1) = inc_clock c t1` by
        (EVAL_TAC \\ fs [bviSemTheory.state_component_equality] \\ DECIDE_TAC) \\ fs []))
  THEN1 (* Op *)
   (`?c1 aux1 n1. compile n xs = (c1,aux1,n1)` by METIS_TAC [PAIR]
    \\ fs [LET_DEF] \\ SRW_TAC [] [] \\ fs [PULL_FORALL]
    \\ `?res5 s5. evaluate (xs,env,s) = (res5,s5)` by METIS_TAC [PAIR]
    \\ fs [] \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`) \\ fs []
    \\ REVERSE (Cases_on `res5`) \\ fs [] \\ SRW_TAC [] []
    \\ first_x_assum (MP_TAC o Q.SPECL [`t1`,`b1`]) \\ fs []
    THEN1 (REPEAT STRIP_TAC \\ IMP_RES_TAC compile_LENGTH \\ fs [iEval_def]
      \\ Q.LIST_EXISTS_TAC [`t2`,`b2`,`c`] \\ fs []
      \\ Cases_on `op` \\ fs [compile_op_def,iEval_def,compile_int_thm]
      \\ BasicProvers.EVERY_CASE_TAC \\ fs [iEval_def,compile_int_thm] \\ NO_TAC)
    \\ REPEAT STRIP_TAC \\ Cases_on `do_app op (REVERSE a) s5` \\ fs []
    \\ TRY(
      rw[] >>
      CHANGED_TAC(imp_res_tac bvlPropsTheory.do_app_err) >>
      rw[] >> Cases_on`a'`>>fs[] >> rw[] >>
      simp[compile_op_def,iEval_def] >>
      CONV_TAC (RESORT_EXISTS_CONV(List.rev)) >>
      map_every qexists_tac[`c`,`b2`] >> simp[] >>
      fs[bEvalOp_def] >>
      Cases_on`REVERSE a`>>fs[]>>
      Cases_on`h`>>fs[]>> Cases_on`t`>>fs[]>>
      simp[adjust_bv_def,iEvalOp_def,do_app_aux_def,bEvalOp_def] >>
      simp[Once bvi_to_bvl_def] >> rw[] >>
      pop_assum mp_tac >> BasicProvers.CASE_TAC >>
      qmatch_assum_rename_tac`FLOOKUP s2.refs k = SOME x` >>
      Cases_on`x`>>simp[] >>
      `FLOOKUP t2.refs (b2 k) = SOME (ByteArray l) ∧ s2.io = t2.io` by (
        first_x_assum(qspec_then`a`strip_assume_tac) >>
        fs[state_rel_def] >>
        first_x_assum(qspec_then`k`kall_tac) >>
        first_x_assum(qspec_then`k`mp_tac) >>
        simp[] )
      \\ simp[Once bvi_to_bvl_def]
      \\ BasicProvers.CASE_TAC >> simp[]
      \\ Cases_on `x` \\ fs [] )
    \\ fs [GSYM PULL_FORALL]
    \\ Cases_on`a'`>>fs[]\\rw[]
    \\ fs [iEvalOp_def]
    \\ Cases_on `?i. op = Const i` \\ fs [] THEN1
     (CONV_TAC SWAP_EXISTS_CONV \\ Q.EXISTS_TAC `b2`
      \\ CONV_TAC SWAP_EXISTS_CONV \\ Q.EXISTS_TAC `c`
      \\ fs [] \\ fs [compile_op_def] \\ Cases_on `c1`
      \\ fs [compile_int_thm,bEvalOp_def,iEval_def]
      \\ Cases_on `REVERSE a` \\ fs [iEval_def,iEvalOp_def]
      \\ fs [EVAL ``do_app_aux (Const 0) [] t2``]
      \\ SRW_TAC [] [adjust_bv_def])
    \\ Cases_on `op = Ref` \\ fs [] THEN1
     (fs [bCompOp_def,iEval_def]
      \\ Q.ABBREV_TAC `b3 = ((LEAST ptr. ptr NOTIN FDOM s5.refs) =+
           (LEAST ptr. ptr NOTIN FDOM (bvi_to_bvl t2).refs)) b2`
      \\ CONV_TAC SWAP_EXISTS_CONV \\ Q.EXISTS_TAC `b3`
      \\ CONV_TAC SWAP_EXISTS_CONV \\ Q.EXISTS_TAC `c`
      \\ fs [map_res_def,iEvalOp_def,do_app_aux_def,bEvalOp_def,LET_DEF]
      \\ Q.ABBREV_TAC `x = (LEAST ptr. ptr NOTIN FDOM s5.refs)`
      \\ Q.ABBREV_TAC `y = LEAST ptr. ptr NOTIN FDOM (bvi_to_bvl t2).refs`
      \\ `~(x IN FDOM s5.refs)` by ALL_TAC THEN1
       (`?p. (\ptr. ptr NOTIN FDOM s5.refs) p` by
          (SIMP_TAC std_ss [] \\ METIS_TAC [NUM_NOT_IN_FDOM])
        \\ IMP_RES_TAC whileTheory.LEAST_INTRO \\ fs []
        \\ REV_FULL_SIMP_TAC std_ss [])
      \\ `~(y IN FDOM t2.refs)` by ALL_TAC THEN1
       (`?p. (\ptr. ptr NOTIN FDOM t2.refs) p` by
          (SIMP_TAC std_ss [] \\ METIS_TAC [NUM_NOT_IN_FDOM])
        \\ IMP_RES_TAC whileTheory.LEAST_INTRO \\ fs [bvi_to_bvl_def]
        \\ REV_FULL_SIMP_TAC (srw_ss()) [bvi_to_bvl_def])
      \\ fs []
      \\ SRW_TAC [] [adjust_bv_def]
      \\ `MAP (adjust_bv b3) env = MAP (adjust_bv b2) env` by ALL_TAC THEN1
       (fs [MEM_EQ_IMP_MAP_EQ] \\ REPEAT STRIP_TAC
        \\ MATCH_MP_TAC bv_ok_IMP_adjust_bv_eq
        \\ fs [EVERY_MEM] \\ RES_TAC
        \\ IMP_RES_TAC evaluate_refs_SUBSET
        \\ REPEAT STRIP_TAC THEN1 METIS_TAC [bv_ok_SUBSET_IMP]
        \\ Q.UNABBREV_TAC `b3` \\ fs [APPLY_UPDATE_THM]
        \\ SRW_TAC [] [] \\ fs [])
      \\ `MAP (adjust_bv b3) a = MAP (adjust_bv b2) a` by ALL_TAC THEN1
       (fs [MEM_EQ_IMP_MAP_EQ] \\ REPEAT STRIP_TAC
        \\ MATCH_MP_TAC bv_ok_IMP_adjust_bv_eq
        \\ IMP_RES_TAC evaluate_ok \\ REV_FULL_SIMP_TAC std_ss [] \\ fs []
        \\ fs [EVERY_MEM] \\ RES_TAC
        \\ Q.UNABBREV_TAC `b3` \\ fs [APPLY_UPDATE_THM]
        \\ SRW_TAC [] [] \\ fs [])
      \\ `MAP (OPTION_MAP (adjust_bv b2)) s5.globals =
          MAP (OPTION_MAP (adjust_bv b3)) s5.globals` by ALL_TAC THEN1
       (fs [MEM_EQ_IMP_MAP_EQ] \\ REPEAT STRIP_TAC
        \\ Cases_on `x'` \\ fs []
        \\ MATCH_MP_TAC bv_ok_IMP_adjust_bv_eq
        \\ IMP_RES_TAC evaluate_ok \\ REV_FULL_SIMP_TAC std_ss [] \\ fs []
        \\ fs [state_ok_def,EVERY_MEM] \\ RES_TAC \\ fs []
        \\ Q.UNABBREV_TAC `b3` \\ fs [APPLY_UPDATE_THM]
        \\ SRW_TAC [] [] \\ fs [])
      \\ fs [] \\ STRIP_TAC
      THEN1 (UNABBREV_ALL_TAC \\ fs [APPLY_UPDATE_THM])
      \\ REVERSE STRIP_TAC THEN1
       (REPEAT STRIP_TAC \\ UNABBREV_ALL_TAC \\ fs [APPLY_UPDATE_THM]
        \\ SRW_TAC [] []
        \\ IMP_RES_TAC evaluate_refs_SUBSET \\ fs [SUBSET_DEF] \\ RES_TAC)
      \\ fs [state_rel_def,bvl_to_bvi_def,bvi_to_bvl_def,FLOOKUP_FAPPLY]
      \\ STRIP_TAC
      THEN1 (Q.UNABBREV_TAC `b3` \\ MATCH_MP_TAC INJ_EXTEND \\ fs [])
      \\ REPEAT STRIP_TAC \\ Cases_on `k = x` \\ fs [rich_listTheory.MAP_REVERSE]
      THEN1 (Q.UNABBREV_TAC `b3` \\ fs [APPLY_UPDATE_THM])
      \\ Cases_on `FLOOKUP s5.refs k = NONE` \\ fs [rich_listTheory.MAP_REVERSE]
      \\ `b3 k <> y` by ALL_TAC \\ fs [] THEN1
       (Q.UNABBREV_TAC `b3` \\ fs [APPLY_UPDATE_THM,FLOOKUP_DEF]
        \\ fs [INJ_DEF] \\ RES_TAC \\ REPEAT STRIP_TAC \\ fs [])
      \\ `b3 k = b2 k` by ALL_TAC
      THEN1 (Q.UNABBREV_TAC `b3` \\ fs [APPLY_UPDATE_THM,FLOOKUP_DEF])
      \\ fs [] \\ Cases_on `FLOOKUP s5.refs k` \\ fs []
      \\ Q.PAT_ASSUM `!k. bbb` MP_TAC
      \\ Q.PAT_ASSUM `!k. bbb` MP_TAC
      \\ Q.PAT_ASSUM `!k. bbb` (MP_TAC o Q.SPEC `k`) \\ fs []
      \\ Cases_on `x'` \\ fs [] \\ REPEAT STRIP_TAC
      \\ fs [MEM_EQ_IMP_MAP_EQ] \\ REPEAT STRIP_TAC
      \\ MATCH_MP_TAC bv_ok_IMP_adjust_bv_eq
      \\ IMP_RES_TAC evaluate_ok \\ REV_FULL_SIMP_TAC std_ss [] \\ fs []
      \\ fs [state_ok_def]
      \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `k`) \\ fs []
      \\ fs [EVERY_MEM] \\ REPEAT STRIP_TAC
      \\ Q.UNABBREV_TAC `b3` \\ fs [APPLY_UPDATE_THM]
      \\ SRW_TAC [] [] \\ fs [])
    \\ `bCompOp op c1 = Op op c1` by
      (Cases_on `op` \\ fs [bCompOp_def] \\ NO_TAC)
    \\ fs [iEval_def,map_res_def]
    \\ CONV_TAC SWAP_EXISTS_CONV \\ Q.EXISTS_TAC `b2`
    \\ CONV_TAC SWAP_EXISTS_CONV \\ Q.EXISTS_TAC `c`
    \\ `EVERY (bv_ok s5.refs) (REVERSE a)` by ALL_TAC
    THEN1 (IMP_RES_TAC evaluate_ok \\ fs [rich_listTheory.EVERY_REVERSE])
    \\ MP_TAC do_app_adjust \\ fs [] \\ REPEAT STRIP_TAC \\ fs [rich_listTheory.MAP_REVERSE])
  THEN1 (* Tick *)
   (`?c1 aux1 n1. compile n [x] = (c1,aux1,n1)` by METIS_TAC [PAIR]
    \\ fs [LET_DEF] \\ SRW_TAC [] [] \\ fs [PULL_FORALL]
    \\ IMP_RES_TAC compile_LENGTH
    \\ `?d. c1 = [d]` by (Cases_on `c1` \\ fs [LENGTH_NIL]) \\ fs []
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`) \\ fs []
    \\ SRW_TAC [] [iEval_def]
    \\ Cases_on `s.clock = 0` \\ fs [] THEN1
     (SRW_TAC [] [] \\ Q.LIST_EXISTS_TAC [`t1`,`b1`,`0`]
      \\ fs [inc_clock_ZERO] \\ fs [state_rel_def]) \\ fs []
    \\ `t1.clock <> 0 /\ !c. (inc_clock c t1).clock <> 0` by
      (EVAL_TAC \\ fs [state_rel_def] \\ DECIDE_TAC) \\ fs []
    \\ REV_FULL_SIMP_TAC std_ss [dec_clock_inv_clock1]
    \\ `(dec_clock 1 s).refs = s.refs` by EVAL_TAC \\ fs []
    \\ Q.PAT_ASSUM `!xx yy. bbb` (MP_TAC o Q.SPECL [`dec_clock 1 t1`,`b1`])
    \\ REV_FULL_SIMP_TAC std_ss [dec_clock_inv_clock1]
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC
    THEN1 (fs [evaluate_ok_lemma]
           \\ fs [state_rel_def,dec_clock_def,bvlSemTheory.dec_clock_def])
    \\ fs [GSYM PULL_FORALL])
  THEN1 (* Call *)
   (`?c1 aux1 n1. compile n xs = (c1,aux1,n1)` by METIS_TAC [PAIR]
    \\ fs [LET_DEF] \\ SRW_TAC [] [] \\ fs [PULL_FORALL]
    \\ `?res5 s5. evaluate (xs,env,s1) = (res5,s5)` by METIS_TAC [PAIR]
    \\ fs [] \\ FIRST_X_ASSUM (MP_TAC o Q.SPEC `n`) \\ fs []
    \\ REVERSE (Cases_on `res5`) \\ fs [] \\ SRW_TAC [] []
    \\ first_x_assum (MP_TAC o Q.SPECL [`t1`,`b1`]) \\ fs []
    \\ TRY (REPEAT STRIP_TAC \\ IMP_RES_TAC compile_LENGTH \\ fs [iEval_def]
      \\ Q.LIST_EXISTS_TAC [`t2`,`b2`,`c`] \\ fs [] \\ NO_TAC)
    \\ fs [GSYM PULL_FORALL] \\ REPEAT STRIP_TAC
    \\ fs [iEval_def]
    \\ Cases_on `find_code dest a s5.code` \\ fs [] \\ Cases_on `x` \\ fs []
    \\ Cases_on `s5.clock < ticks + 1` \\ fs [] THEN1
     (Q.LIST_EXISTS_TAC [`t2 with clock := 0`,`b2`,`c`] \\ fs []
      \\ SRW_TAC [] []
      \\ TRY (fs [state_rel_def] \\ NO_TAC)
      \\ `t2.clock < ticks + 1` by (fs [state_rel_def] \\ rfs [])
      \\ fs []
      \\ REVERSE (Cases_on `dest`)
      \\ fs [bvlSemTheory.find_code_def,find_code_def]
      THEN1
       (Cases_on `lookup x s5.code` \\ fs []
        \\ Cases_on `x'` \\ fs [] \\ SRW_TAC [] []
        \\ fs [state_rel_def] \\ RES_TAC
        \\ `?x1 x2 x3. compile n' [r] = (x1,x2,x3)` by METIS_TAC [PAIR]
        \\ fs [LET_DEF])
      \\ `?x1 l1. a = SNOC x1 l1` by METIS_TAC [SNOC_CASES]
      \\ fs [] \\ Cases_on `x1` \\ fs [adjust_bv_def]
      \\ Cases_on `lookup n' s5.code` \\ fs []
      \\ Cases_on `x` \\ fs [] \\ SRW_TAC [] []
      \\ fs [state_rel_def] \\ RES_TAC
      \\ `?x1 x2 x3. compile n'' [r] = (x1,x2,x3)` by METIS_TAC [PAIR]
      \\ fs [LET_DEF])
    \\ Q.MATCH_ASSUM_RENAME_TAC `find_code dest a s5.code = SOME (args,body)`
    \\ `?n7. let (c7,aux7,n8) = compile n7 [body] in
               (find_code (case dest of NONE => NONE | SOME n => SOME (2 * n))
                 (MAP (adjust_bv b2) a) t2.code =
                 SOME (MAP (adjust_bv b2) args,HD c7)) /\
               aux_code_installed aux7 t2.code /\
               bEvery GoodHandleLet [body]` by ALL_TAC THEN1
     (REVERSE (Cases_on `dest`) \\ fs [state_rel_def,find_code_def]
      THEN1 (Cases_on `lookup x s5.code` \\ fs [] \\ Cases_on `x'` \\ fs []
        \\ SRW_TAC [] []
        \\ FIRST_X_ASSUM (qspecl_then
             [`x`,`LENGTH a`,`body`]mp_tac) \\ fs []
        \\ REPEAT STRIP_TAC \\ Q.EXISTS_TAC `n'` \\ fs []
        \\ `?c2 aux2 n2. compile n' [body] = (c2,aux2,n2)` by METIS_TAC [PAIR]
        \\ fs [LET_DEF])
      \\ `?a1 a2. a = SNOC a1 a2` by METIS_TAC [SNOC_CASES]
      \\ fs [] \\ Cases_on `a1` \\ fs []
      \\ FULL_SIMP_TAC std_ss [GSYM SNOC_APPEND,FRONT_SNOC]
      \\ Cases_on `lookup n' s5.code` \\ fs [] \\ Cases_on `x` \\ fs []
      \\ SRW_TAC [] []
      \\ Q.PAT_ASSUM `!x1 x2. bbb` (MP_TAC o Q.SPECL [`n'`]) \\ fs []
      \\ REPEAT STRIP_TAC \\ Q.EXISTS_TAC `n''`
      \\ `?c2 aux2 n2. compile n'' [body] = (c2,aux2,n2)` by METIS_TAC [PAIR]
      \\ fs [LET_DEF,adjust_bv_def])
    \\ `?c7 aux7 n8. compile n7 [body] = (c7,aux7,n8)` by METIS_TAC [PAIR]
    \\ fs [LET_DEF]
    \\ `¬(t2.clock < ticks + 1)` by (fs [state_rel_def] \\ REV_FULL_SIMP_TAC std_ss [])
    \\ fs [] \\ IMP_RES_TAC compile_LENGTH
    \\ `?d. c7 = [d]` by (Cases_on `c7` \\ fs [LENGTH_NIL]) \\ fs []
    \\ Q.PAT_ASSUM `!nn mm. bbb` (MP_TAC o Q.SPEC `n7`) \\ fs []
    \\ STRIP_TAC
    \\ FIRST_X_ASSUM (MP_TAC o Q.SPECL [`dec_clock (ticks + 1) t2`,`b2`]) \\ fs []
    \\ MATCH_MP_TAC IMP_IMP \\ STRIP_TAC THEN1
     (`(dec_clock (ticks + 1) t2).code = t2.code` by (EVAL_TAC \\ fs [])
      \\ `(dec_clock (ticks + 1) t2).refs = t2.refs` by (EVAL_TAC \\ fs [])
      \\ IMP_RES_TAC evaluate_ok
      \\ fs [evaluate_ok_lemma] \\ REV_FULL_SIMP_TAC std_ss []
      \\ STRIP_TAC THEN1
        (fs [state_rel_def,dec_clock_def,bvlSemTheory.dec_clock_def])
      \\ IMP_RES_TAC find_code_EVERY_IMP)
    \\ STRIP_TAC
    \\ Q.LIST_EXISTS_TAC [`t2'`,`b2'`,`c' + c`] \\ fs []
    \\ IMP_RES_TAC evaluate_inv_clock
    \\ fs [inc_clock_ADD]
    \\ REV_FULL_SIMP_TAC std_ss []
    \\ `MAP (adjust_bv b2') env = MAP (adjust_bv b2) env` by
     (fs [MEM_EQ_IMP_MAP_EQ] \\ REPEAT STRIP_TAC
      \\ MATCH_MP_TAC (bv_ok_IMP_adjust_bv_eq |> GEN_ALL)
      \\ Q.EXISTS_TAC `s5` \\ fs [bvlSemTheory.dec_clock_def]
      \\ IMP_RES_TAC evaluate_refs_SUBSET
      \\ IMP_RES_TAC bv_ok_SUBSET_IMP \\ fs [EVERY_MEM] \\ NO_TAC)
    \\ `(inc_clock c' t2).code = t2.code` by (EVAL_TAC \\ fs []) \\ fs []
    \\ `¬((inc_clock c' t2).clock < ticks + 1)` by (fs [inc_clock_def] \\ decide_tac)
    \\ fs []
    \\ REV_FULL_SIMP_TAC std_ss [dec_clock_inv_clock]
    \\ fs [bvlSemTheory.dec_clock_def]
    \\ IMP_RES_TAC evaluate_refs_SUBSET \\ fs [SUBSET_DEF]
    \\ Cases_on `res` \\ fs []
    \\ Cases_on`e` \\ fs[]));

val _ = save_thm("compile_correct",compile_correct);

val _ = export_theory();
