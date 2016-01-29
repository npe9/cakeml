open preamble;
open rich_listTheory alistTheory;
open miscTheory;
open libTheory typeSystemTheory astTheory semanticPrimitivesTheory terminationTheory inferTheory unifyTheory infer_tTheory;
open astPropsTheory;
open inferPropsTheory;
open typeSysPropsTheory;

local open typeSoundInvariantsTheory in
val tenvT_ok_def = tenvT_ok_def;
val flat_tenvT_ok_def = flat_tenvT_ok_def;
end

val o_f_id = Q.prove (
`!m. (\x.x) o_f m = m`,
srw_tac[] [fmap_EXT]);

val _ = new_theory "infer_eSound";



(* ---------- sub_completion ---------- *)

val sub_completion_unify = Q.prove (
`!st t1 t2 s1 n ts s2 n.
  (t_unify st.subst t1 t2 = SOME s1) ∧
  sub_completion n (st.next_uvar + 1) s1 ts s2
  ⇒
  sub_completion n st.next_uvar st.subst ((t1,t2)::ts) s2`,
srw_tac[] [sub_completion_def, pure_add_constraints_def] >>
full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF, count_add1]);

val sub_completion_unify2 = Q.store_thm ("sub_completion_unify2",
`!st t1 t2 s1 n ts s2 n s3 next_uvar.
  (t_unify s1 t1 t2 = SOME s2) ∧
  sub_completion n next_uvar s2 ts s3
  ⇒
  sub_completion n next_uvar s1 ((t1,t2)::ts) s3`,
srw_tac[] [sub_completion_def, pure_add_constraints_def]);

val sub_completion_infer = Q.prove (
`!menv cenv env e st1 t st2 n ts2 s.
  (infer_e menv cenv env e st1 = (Success t, st2)) ∧
  sub_completion n st2.next_uvar st2.subst ts2 s
  ⇒
  ?ts1. sub_completion n st1.next_uvar st1.subst (ts1 ++ ts2) s`,
srw_tac[] [sub_completion_def, pure_add_constraints_append] >>
imp_res_tac infer_e_constraints >>
imp_res_tac infer_e_next_uvar_mono >>
qexists_tac `ts` >>
srw_tac[] [] >|
[qexists_tac `st2.subst` >>
     srw_tac[] [],
 full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF]]);

val sub_completion_add_constraints = Q.store_thm ("sub_completion_add_constraints",
`!s1 ts1 s2 n next_uvar s2 s3 ts2.
  pure_add_constraints s1 ts1 s2 ∧
  sub_completion n next_uvar s2 ts2 s3
  ⇒
  sub_completion n next_uvar s1 (ts1++ts2) s3`,
induct_on `ts1` >>
srw_tac[] [pure_add_constraints_def] >>
Cases_on `h` >>
full_simp_tac(srw_ss()) [pure_add_constraints_def] >>
res_tac >>
full_simp_tac(srw_ss()) [sub_completion_def] >>
srw_tac[] [] >>
full_simp_tac(srw_ss()) [pure_add_constraints_def, pure_add_constraints_append] >>
metis_tac []);

val sub_completion_more_vars = Q.prove (
`!m n1 n2 s1 ts s2.
  sub_completion m (n1 + n2) s1 ts s2 ⇒ sub_completion m n1 s1 ts s2`,
srw_tac[] [sub_completion_def] >>
srw_tac[] [] >>
full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF]);

val sub_completion_infer_es = Q.prove (
`!menv cenv env es st1 t st2 n ts2 s.
  (infer_es menv cenv env es st1 = (Success t, st2)) ∧
  sub_completion n st2.next_uvar st2.subst ts2 s
  ⇒
  ?ts1. sub_completion n st1.next_uvar st1.subst (ts1 ++ ts2) s`,
induct_on `es` >>
srw_tac[] [infer_e_def, success_eqns] >-
metis_tac [APPEND] >>
res_tac >>
imp_res_tac sub_completion_infer >>
metis_tac [APPEND_ASSOC]);

val sub_completion_infer_p = Q.store_thm ("sub_completion_infer_p",
`(!cenv p st t env st' tvs extra_constraints s.
    (infer_p cenv p st = (Success (t,env), st')) ∧
    sub_completion tvs st'.next_uvar st'.subst extra_constraints s
    ⇒
    ?ts. sub_completion tvs st.next_uvar st.subst (ts++extra_constraints) s) ∧
 (!cenv ps st ts env st' tvs extra_constraints s.
    (infer_ps cenv ps st = (Success (ts,env), st')) ∧
    sub_completion tvs st'.next_uvar st'.subst extra_constraints s
    ⇒
    ?ts. sub_completion tvs st.next_uvar st.subst (ts++extra_constraints) s)`,
ho_match_mp_tac infer_p_ind >>
srw_tac[] [infer_p_def, success_eqns, remove_pair_lem] >>
full_simp_tac(srw_ss()) [] >|
[metis_tac [APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 PairCases_on `v'` >>
     full_simp_tac(srw_ss()) [] >>
     metis_tac [APPEND_ASSOC, APPEND, sub_completion_more_vars],
 imp_res_tac sub_completion_add_constraints >>
     PairCases_on `v''` >>
     full_simp_tac(srw_ss()) [] >>
     metis_tac [APPEND_ASSOC, APPEND, sub_completion_more_vars],
 PairCases_on `v'` >>
     full_simp_tac(srw_ss()) [] >>
     metis_tac [APPEND_ASSOC, APPEND, sub_completion_more_vars],
 metis_tac [APPEND, sub_completion_more_vars],
 PairCases_on `v'` >>
     PairCases_on `v''` >>
     full_simp_tac(srw_ss()) [] >>
     metis_tac [APPEND_ASSOC]]);

val sub_completion_infer_pes = Q.prove (
`!menv cenv env pes t1 t2 st1 t st2 n ts2 s.
  (infer_pes menv cenv env pes t1 t2 st1 = (Success (), st2)) ∧
  sub_completion n st2.next_uvar st2.subst ts2 s
  ⇒
  ?ts1. sub_completion n st1.next_uvar st1.subst (ts1 ++ ts2) s`,
induct_on `pes` >>
srw_tac[] [infer_e_def, success_eqns] >-
metis_tac [APPEND] >>
PairCases_on `h` >>
full_simp_tac(srw_ss()) [infer_e_def, success_eqns] >>
PairCases_on `v'` >>
full_simp_tac(srw_ss()) [infer_e_def, success_eqns] >>
srw_tac[] [] >>
res_tac >>
full_simp_tac(srw_ss()) [] >>
imp_res_tac sub_completion_unify2 >>
imp_res_tac sub_completion_infer >>
full_simp_tac(srw_ss()) [] >>
imp_res_tac sub_completion_unify2 >>
imp_res_tac sub_completion_infer_p >>
full_simp_tac(srw_ss()) [] >>
metis_tac [APPEND, APPEND_ASSOC]);

val sub_completion_infer_funs = Q.prove (
`!menv cenv env funs st1 t st2 n ts2 s.
  (infer_funs menv cenv env funs st1 = (Success t, st2)) ∧
  sub_completion n st2.next_uvar st2.subst ts2 s
  ⇒
  ?ts1. sub_completion n st1.next_uvar st1.subst (ts1 ++ ts2) s`,
induct_on `funs` >>
srw_tac[] [infer_e_def, success_eqns] >-
metis_tac [APPEND] >>
PairCases_on `h` >>
full_simp_tac(srw_ss()) [infer_e_def, success_eqns] >>
res_tac >>
imp_res_tac sub_completion_infer >>
full_simp_tac(srw_ss()) [] >>
metis_tac [sub_completion_more_vars, APPEND_ASSOC]);

val sub_completion_apply = Q.store_thm ("sub_completion_apply",
`!n uvars s1 ts s2 t1 t2.
  t_wfs s1 ∧
  (t_walkstar s1 t1 = t_walkstar s1 t2) ∧
  sub_completion n uvars s1 ts s2 
  ⇒
  (t_walkstar s2 t1 = t_walkstar s2 t2)`,
srw_tac[] [sub_completion_def] >>
pop_assum (fn _ => all_tac) >>
pop_assum (fn _ => all_tac) >>
pop_assum mp_tac >>
pop_assum mp_tac >>
pop_assum mp_tac >>
Q.SPEC_TAC (`s1`, `s1`) >>
induct_on `ts` >>
srw_tac[] [pure_add_constraints_def] >-
metis_tac [] >>
cases_on `h` >>
full_simp_tac(srw_ss()) [pure_add_constraints_def] >>
full_simp_tac(srw_ss()) [] >>
metis_tac [t_unify_apply2, t_unify_wfs]);

val sub_completion_apply_list = Q.prove (
`!n uvars s1 ts s2 ts1 ts2.
  t_wfs s1 ∧
  (MAP (t_walkstar s1) ts1 = MAP (t_walkstar s1) ts2) ∧
  sub_completion n uvars s1 ts s2 
  ⇒
  (MAP (t_walkstar s2) ts1 = MAP (t_walkstar s2) ts2)`,
induct_on `ts1` >>
srw_tac[] [] >>
cases_on `ts2` >>
full_simp_tac(srw_ss()) [] >>
metis_tac [sub_completion_apply]);

val sub_completion_check = Q.prove (
`!tvs m s uvar s' extra_constraints.
sub_completion m (uvar + tvs) s' extra_constraints s
⇒
EVERY (λn. check_freevars m [] (convert_t (t_walkstar s (Infer_Tuvar (uvar + n))))) (COUNT_LIST tvs)`,
induct_on `tvs` >>
srw_tac[] [sub_completion_def, COUNT_LIST_SNOC, EVERY_SNOC] >>
full_simp_tac(srw_ss()) [sub_completion_def] >|
[qpat_assum `!m' s. P m' s` match_mp_tac >>
     srw_tac[] [] >>
     qexists_tac `s'` >>
     qexists_tac `extra_constraints` >>
     srw_tac[] [] >>
     full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF],
 full_simp_tac(srw_ss()) [SUBSET_DEF] >>
     `uvar+tvs < uvar + SUC tvs`
            by full_simp_tac (srw_ss()++ARITH_ss) [SUBSET_DEF] >>
     metis_tac [check_t_to_check_freevars]]);

(* ---------- Soundness ---------- *)

val type_pes_def = Define `
type_pes menv cenv tenv pes t1 t2 =
  ∀x::set pes.
    (λ(p,e).
       ∃tenv'.
         ALL_DISTINCT (pat_bindings p []) ∧
         type_p (num_tvs tenv) cenv p t1 tenv' ∧
         type_e menv cenv (bind_var_list 0 tenv' tenv) e t2) x`;

val type_pes_cons = Q.prove (
`!menv cenv tenv p e pes t1 t2.
  type_pes menv cenv tenv ((p,e)::pes) t1 t2 =
  (ALL_DISTINCT (pat_bindings p []) ∧
   (?tenv'.
       type_p (num_tvs tenv) cenv p t1 tenv' ∧
       type_e menv cenv (bind_var_list 0 tenv' tenv) e t2) ∧
   type_pes menv cenv tenv pes t1 t2)`,
srw_tac[] [type_pes_def, RES_FORALL] >>
eq_tac >>
srw_tac[] [] >>
srw_tac[] [] >|
[pop_assum (mp_tac o Q.SPEC `(p,e)`) >>
     srw_tac[] [],
 pop_assum (mp_tac o Q.SPEC `(p,e)`) >>
     srw_tac[] [] >>
     metis_tac [],
 metis_tac []]);

val infer_p_sound = Q.store_thm ("infer_p_sound",
`(!cenv p st t env st' tvs extra_constraints s.
    (infer_p cenv p st = (Success (t,env), st')) ∧
    t_wfs st.subst ∧
    check_cenv cenv ∧
    sub_completion tvs st'.next_uvar st'.subst extra_constraints s
    ⇒
    type_p tvs cenv p (convert_t (t_walkstar s t)) (convert_env s env)) ∧
 (!cenv ps st ts env st' tvs extra_constraints s.
    (infer_ps cenv ps st = (Success (ts,env), st')) ∧
    t_wfs st.subst ∧
    check_cenv cenv ∧
    sub_completion tvs st'.next_uvar st'.subst extra_constraints s
    ⇒
    type_ps tvs cenv ps (MAP (convert_t o t_walkstar s) ts) (convert_env s env))`,
ho_match_mp_tac infer_p_ind >>
srw_tac[] [infer_p_def, success_eqns, remove_pair_lem] >>
srw_tac[] [Once type_p_cases, convert_env_def] >>
imp_res_tac sub_completion_wfs >>
full_simp_tac(srw_ss()) [] >>
srw_tac[] [t_walkstar_eqn1, convert_t_def, Tint_def, Tstring_def, Tchar_def] >|
[match_mp_tac check_t_to_check_freevars >>
     srw_tac[] [] >>
     full_simp_tac(srw_ss()) [sub_completion_def] >>
     qpat_assum `!uv. uv ∈ FDOM s ⇒ P uv` match_mp_tac >>
     full_simp_tac(srw_ss()) [count_def, SUBSET_DEF],
 `?ts env. v' = (ts,env)` by (PairCases_on `v'` >> metis_tac []) >>
     `t_wfs s` by metis_tac [infer_p_wfs] >>
     srw_tac[] [t_walkstar_eqn1, convert_t_def, Tref_def] >>
     full_simp_tac(srw_ss()) [convert_env_def] >>
     metis_tac [MAP_MAP_o],
 `?ts env. v'' = (ts,env)` by (PairCases_on `v''` >> metis_tac []) >>
     `?tvs ts tn. v' = (tvs,ts,tn)` by (PairCases_on `v'` >> metis_tac []) >>
     srw_tac[] [] >>
     `type_ps tvs cenv ps (MAP (convert_t o t_walkstar s) ts) (convert_env s env)` 
               by metis_tac [sub_completion_add_constraints, sub_completion_more_vars] >>
     srw_tac[] [] >>
     `t_wfs s` by metis_tac [sub_completion_wfs, infer_p_wfs, pure_add_constraints_wfs] >>
     srw_tac[] [convert_t_def, t_walkstar_eqn1, MAP_MAP_o, combinTheory.o_DEF,
         EVERY_MAP, LENGTH_COUNT_LIST] >>
     full_simp_tac(srw_ss()) [] >-
     metis_tac [sub_completion_check] >>
     `t_wfs st'''.subst` by metis_tac [infer_p_wfs] >>
     imp_res_tac pure_add_constraints_apply >>
     pop_assum (fn _ => all_tac) >>
     pop_assum (fn _ => all_tac) >>
     pop_assum mp_tac >>
     srw_tac[] [MAP_ZIP] >>
     `t_wfs st'.subst` by metis_tac [pure_add_constraints_wfs] >>
     imp_res_tac sub_completion_apply_list >>
     NTAC 6 (pop_assum (fn _ => all_tac)) >>
     pop_assum mp_tac >>
     srw_tac[] [subst_infer_subst_swap] >>
     `EVERY (check_freevars 0 tvs') ts'` by metis_tac [check_cenv_lookup] >>
     srw_tac[] [] >>
     full_simp_tac(srw_ss()) [convert_env_def] >>
     metis_tac [convert_t_subst, LENGTH_COUNT_LIST, LENGTH_MAP,
                MAP_MAP_o, combinTheory.o_DEF],
 `?ts env. v' = (ts,env)` by (PairCases_on `v'` >> metis_tac []) >>
     `t_wfs s` by metis_tac [infer_p_wfs] >>
     srw_tac[] [t_walkstar_eqn1, convert_t_def, Tref_def] >>
     full_simp_tac(srw_ss()) [convert_env_def] >>
     metis_tac [],
 `?t env. v' = (t,env)` by (PairCases_on `v'` >> metis_tac []) >>
     `?ts' env'. v'' = (ts',env')` by (PairCases_on `v''` >> metis_tac []) >>
     srw_tac[] [] >>
     `t_wfs st''.subst` by metis_tac [infer_p_wfs] >>
     `?ts. sub_completion tvs st''.next_uvar st''.subst ts s` by metis_tac [sub_completion_infer_p] >>
     full_simp_tac(srw_ss()) [convert_env_def] >>
     metis_tac []]);

val letrec_lemma = Q.prove (
`!funs funs_ts s st. 
  (MAP (λn. convert_t (t_walkstar s (Infer_Tuvar (st.next_uvar + n)))) (COUNT_LIST (LENGTH funs)) =
   MAP (\t. convert_t (t_walkstar s t)) funs_ts)
  ⇒
  (MAP2 (λ(f,x,e) t. (f,t)) funs (MAP (λn. convert_t (t_walkstar s (Infer_Tuvar (st.next_uvar + n)))) (COUNT_LIST (LENGTH funs))) =
   MAP2 (λ(x,y,z) t. (x,convert_t (t_walkstar s t))) funs funs_ts)`,
induct_on `funs` >>
srw_tac[] [] >>
cases_on `funs_ts` >>
full_simp_tac(srw_ss()) [COUNT_LIST_def] >>
srw_tac[] [] >|
[PairCases_on `h` >>
     srw_tac[] [],
 qpat_assum `!x. P x` match_mp_tac >>
     qexists_tac `st with next_uvar := st.next_uvar + 1` >>
     full_simp_tac(srw_ss()) [MAP_MAP_o, combinTheory.o_DEF, DECIDE ``x + SUC y = x + 1 + y``]]);

val map_zip_lem = Q.prove (
`!funs ts. 
  (LENGTH funs = LENGTH ts)
  ⇒
  (MAP (λx. FST ((λ((x',y,z),t). (x',convert_t (t_walkstar s t))) x)) (ZIP (funs,ts))
   =
   MAP FST funs)`,
induct_on `funs` >>
srw_tac[] [] >>
cases_on `ts` >>
full_simp_tac(srw_ss()) [] >>
PairCases_on `h` >>
srw_tac[] []);

val binop_tac =
imp_res_tac infer_e_wfs >>
imp_res_tac t_unify_wfs >>
full_simp_tac(srw_ss()) [] >>
imp_res_tac sub_completion_unify2 >>
imp_res_tac sub_completion_infer >>
full_simp_tac(srw_ss()) [] >>
res_tac >>
full_simp_tac(srw_ss()) [] >>
imp_res_tac t_unify_apply >>
imp_res_tac sub_completion_apply >>
imp_res_tac t_unify_wfs >>
imp_res_tac sub_completion_wfs >>
full_simp_tac(srw_ss()) [t_walkstar_eqn, t_walk_eqn, convert_t_def, deBruijn_inc_def, check_t_def] >>
srw_tac[] [type_op_cases, Tint_def, Tstring_def, Tref_def, Tfn_def, Texn_def, Tchar_def] >>
metis_tac [MAP, infer_e_next_uvar_mono, check_env_more];

val constrain_op_sub_completion = Q.prove (
`sub_completion (num_tvs tenv) st.next_uvar st.subst extra_constraints s ∧
 constrain_op op ts st' = (Success t,st)
 ⇒
 ∃c. sub_completion (num_tvs tenv) st'.next_uvar st'.subst c s`,
 srw_tac[] [] >>
 full_simp_tac(srw_ss()) [constrain_op_success] >>
 every_case_tac >>
 full_simp_tac(srw_ss()) [success_eqns] >>
 srw_tac[] [] >>
 full_simp_tac(srw_ss()) [infer_st_rewrs] >>
 metis_tac [sub_completion_unify2, sub_completion_unify]);

val constrain_op_sound = Q.prove (
`t_wfs st.subst ∧
 sub_completion (num_tvs tenv) st'.next_uvar st'.subst c s ∧
 constrain_op op ts st = (Success t,st')
 ⇒
 type_op op (MAP (convert_t o t_walkstar s) ts) (convert_t (t_walkstar s t))`,
 full_simp_tac(srw_ss()) [constrain_op_def, type_op_cases] >>
 every_case_tac >>
 full_simp_tac(srw_ss()) [success_eqns] >>
 srw_tac[] [] >>
 full_simp_tac(srw_ss()) [infer_st_rewrs,Tchar_def] >>
 binop_tac);

val infer_e_sound = Q.store_thm ("infer_e_sound",
`(!menv cenv env e st st' tenv t extra_constraints s tenvM.
    (infer_e menv cenv env e st = (Success t, st')) ∧
    t_wfs st.subst ∧
    check_menv menv ∧
    check_cenv cenv ∧
    check_env (count st.next_uvar) env ∧
    sub_completion (num_tvs tenv) st'.next_uvar st'.subst extra_constraints s ∧
    tenv_inv s env tenv ∧ 
    menv_alpha menv tenvM
    ⇒
    type_e tenvM cenv tenv e 
           (convert_t (t_walkstar s t))) ∧
 (!menv cenv env es st st' tenv ts extra_constraints s tenvM .
    (infer_es menv cenv env es st = (Success ts, st')) ∧
    t_wfs st.subst ∧
    check_menv menv ∧
    check_cenv cenv ∧
    check_env (count st.next_uvar) env ∧
    sub_completion (num_tvs tenv) st'.next_uvar st'.subst extra_constraints s ∧
    tenv_inv s env tenv ∧ 
    menv_alpha menv tenvM
    ⇒
    type_es tenvM cenv tenv es 
            (MAP (convert_t o t_walkstar s) ts)) ∧
 (!menv cenv env pes t1 t2 st st' tenv extra_constraints s tenvM .
    (infer_pes menv cenv env pes t1 t2 st = (Success (), st')) ∧
    t_wfs st.subst ∧
    check_menv menv ∧
    check_cenv cenv ∧
    check_env (count st.next_uvar) env ∧
    sub_completion (num_tvs tenv) st'.next_uvar st'.subst extra_constraints s ∧
    tenv_inv s env tenv ∧ 
    menv_alpha menv tenvM
    ⇒
    type_pes tenvM cenv tenv pes (convert_t (t_walkstar s t1)) (convert_t (t_walkstar s t2))) ∧
 (!menv cenv env funs st st' tenv extra_constraints s ts tenvM.
    (infer_funs menv cenv env funs st = (Success ts, st')) ∧
    t_wfs st.subst ∧
    check_menv menv ∧
    check_cenv cenv ∧
    check_env (count st.next_uvar) env ∧
    sub_completion (num_tvs tenv) st'.next_uvar st'.subst extra_constraints s ∧
    tenv_inv s env tenv ∧
    menv_alpha menv tenvM ∧ 
    ALL_DISTINCT (MAP FST funs)
    ⇒
    type_funs tenvM cenv tenv funs (MAP2 (\(x,y,z) t. (x, (convert_t o t_walkstar s) t)) funs ts))`,
  ho_match_mp_tac infer_e_ind >>
  srw_tac[] [infer_e_def, success_eqns, remove_pair_lem] >>
  srw_tac[] [check_t_def] >>
  full_simp_tac(srw_ss()) [check_t_def, check_env_bind, check_env_merge] >>
  ONCE_REWRITE_TAC [type_e_cases] >>
  srw_tac[] [Tint_def, Tchar_def]
  >-
  (* Raise *)
     (full_simp_tac(srw_ss()) [sub_completion_def, flookup_thm, count_add1, SUBSET_DEF] >>
     `st''.next_uvar < st''.next_uvar + 1` by decide_tac >>
     metis_tac [IN_INSERT, check_convert_freevars, prim_recTheory.LESS_REFL])
  >-
 (* Raise *)
     (imp_res_tac sub_completion_unify >>
     `type_e tenvM cenv tenv e (convert_t (t_walkstar s t2))` by metis_tac [] >>
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac t_unify_apply >>
     imp_res_tac sub_completion_apply >>
     imp_res_tac t_unify_wfs >>
     full_simp_tac(srw_ss()) [] >>
     srw_tac[] [] >>
     imp_res_tac sub_completion_wfs >>
     full_simp_tac(srw_ss()) [t_walkstar_eqn1, convert_t_def, Texn_def])
  >-
     (`?ts. sub_completion (num_tvs tenv) st''.next_uvar st''.subst  ts s` 
              by (imp_res_tac sub_completion_infer_pes >>
                  full_simp_tac(srw_ss()) [] >>
                  metis_tac [sub_completion_more_vars]) >>
     metis_tac [])
  >-
     (`?ts. sub_completion (num_tvs tenv) st''.next_uvar st''.subst  ts s` 
              by (imp_res_tac sub_completion_infer_pes >>
                  full_simp_tac(srw_ss()) [] >>
                  metis_tac [sub_completion_more_vars]) >>
     srw_tac[] [RES_FORALL] >>
     `?p e. x = (p,e)` by (PairCases_on `x` >> metis_tac []) >>
     srw_tac[] [] >>
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     `st.next_uvar ≤ st''.next_uvar` by metis_tac [infer_e_next_uvar_mono] >>
     `check_env (count st''.next_uvar) env` by metis_tac [check_env_more] >>
     `type_pes (tenvM) cenv tenv pes (convert_t (t_walkstar s (Infer_Tapp [] TC_exn))) (convert_t (t_walkstar s t))`
              by metis_tac [] >>
     full_simp_tac(srw_ss()) [type_pes_def, RES_FORALL] >>
     pop_assum (mp_tac o Q.SPEC `(p,e')`) >>
     srw_tac[] [Texn_def] >>
     imp_res_tac sub_completion_wfs >>
     full_simp_tac(srw_ss()) [t_walkstar_eqn1, convert_t_def, Texn_def] >>
     metis_tac [])
  >-
 (* Lit int *)
     binop_tac
  >-
 (* Lit char *)
     binop_tac
  >-
 (* Lit string *)
     binop_tac
 (* Lit word8 *)
 >-
     binop_tac
 (* Var short *)
 >-
     (srw_tac[] [t_lookup_var_id_def] >>
     `?tvs t. v' = (tvs, t)` 
                by (PairCases_on `v'` >>
                    srw_tac[] []) >>
     srw_tac[] [] >>
     full_simp_tac(srw_ss())[tenv_inv_def]>>res_tac>>
     full_simp_tac(srw_ss())[check_env_def]>>pop_assum mp_tac>> IF_CASES_TAC>>srw_tac[][]
     >-
       (full_simp_tac(srw_ss())[sub_completion_def]>>
        Q.ISPECL_THEN [`t`,`s`,`tvs`,`st.next_uvar`,`num_tvs tenv`] mp_tac (db_subst_infer_subst_swap|>CONJ_PAIR|>fst) >>
        miscLib.discharge_hyps_keep>-
          (full_simp_tac(srw_ss())[]>>
          metis_tac[pure_add_constraints_wfs,check_t_more])
        >>
        srw_tac[][] >>
        imp_res_tac inc_wfs>>
        pop_assum kall_tac>>pop_assum (qspec_then`tvs` assume_tac)>>
        imp_res_tac t_walkstar_no_vars>>full_simp_tac(srw_ss())[]>>
        qpat_assum`A=convert_t t` (SUBST_ALL_TAC o SYM)>>
        full_simp_tac(srw_ss())[]>>
        qpat_abbrev_tac `ls:t list = MAP A (MAP B (COUNT_LIST tvs))`>>
        assume_tac (deBruijn_subst2|>CONJ_PAIR|>fst)>>
        pop_assum(qspecl_then[`t'`,`0`,`subst`,`ls`,`ARB`] mp_tac)>>
        miscLib.discharge_hyps>-full_simp_tac(srw_ss())[]>>
        srw_tac[][]>>
        full_simp_tac(srw_ss())[deBruijn_inc0]>>
        qexists_tac`MAP (deBruijn_subst 0 ls) subst`>>
        full_simp_tac(srw_ss())[EVERY_MAP]>>
        (*
          Almost done:
          Need something like num_tvs tenv ≥ tvs
          i.e. that the type system's env is consistent
        *)
        full_simp_tac(srw_ss())[EVERY_MEM]>>srw_tac[][]>>
        match_mp_tac deBruijn_subst_check_freevars2>>
        full_simp_tac(srw_ss())[Abbr`ls`,LENGTH_COUNT_LIST]>>
        full_simp_tac(srw_ss())[EVERY_MAP,EVERY_MEM,MEM_COUNT_LIST]>>srw_tac[][]>>
        `st.next_uvar+ n' ∈ FDOM s` by 
          full_simp_tac(srw_ss())[SUBSET_DEF]>>
        metis_tac[check_t_to_check_freevars])
     >>
       (qexists_tac`[]`>>full_simp_tac(srw_ss())[COUNT_LIST_def,infer_deBruijn_subst_id,deBruijn_subst_id]>>
       full_simp_tac(srw_ss())[COUNT_LIST_def,infer_deBruijn_subst_id,sub_completion_def]>>
       metis_tac[deBruijn_subst_nothing]))
 >-
 (* Var long *)
     (
     srw_tac[] [t_lookup_var_id_def]>>
     full_simp_tac(srw_ss())[menv_alpha_def,fmap_rel_OPTREL_FLOOKUP]>>
     last_x_assum(qspec_then`mn` assume_tac)>>
     rev_full_simp_tac(srw_ss())[optionTheory.OPTREL_def]>>
     full_simp_tac(srw_ss())[tenv_alpha_def,tenv_inv_def]>>
      `?tvs t. v' = (tvs, t)` 
                by (PairCases_on `v'` >>
                    srw_tac[] []) >>
     full_simp_tac(srw_ss())[GSYM bvl2_lookup]>>
     res_tac>>
     full_simp_tac(srw_ss())[]>>
     pop_assum mp_tac>>IF_CASES_TAC>>srw_tac[][]
     >-
       (full_simp_tac(srw_ss())[sub_completion_def]>>
        Q.ISPECL_THEN [`t`,`s`,`tvs`,`st.next_uvar`,`num_tvs tenv`] mp_tac (db_subst_infer_subst_swap|>CONJ_PAIR|>fst) >>
        miscLib.discharge_hyps_keep>-
          (full_simp_tac(srw_ss())[]>>
          metis_tac[pure_add_constraints_wfs,check_t_more])
        >>
        srw_tac[][] >>
        imp_res_tac inc_wfs>>
        pop_assum kall_tac>>pop_assum (qspec_then`tvs` assume_tac)>>
        imp_res_tac t_walkstar_no_vars>>full_simp_tac(srw_ss())[]>>
        qpat_assum`A=convert_t t` (SUBST_ALL_TAC o SYM)>>
        full_simp_tac(srw_ss())[]>>
        qpat_abbrev_tac `ls:t list = MAP A (MAP B (COUNT_LIST tvs))`>>
        assume_tac (deBruijn_subst2|>CONJ_PAIR|>fst)>>
        pop_assum(qspecl_then[`t''`,`0`,`subst`,`ls`,`ARB`] mp_tac)>>
        miscLib.discharge_hyps>-
          full_simp_tac(srw_ss())[]>>
        srw_tac[][]>>
        full_simp_tac(srw_ss())[deBruijn_inc0]>>
        qexists_tac`MAP (deBruijn_subst 0 ls) subst`>>
        full_simp_tac(srw_ss())[EVERY_MAP]>>
        full_simp_tac(srw_ss())[EVERY_MEM]>>srw_tac[][]>>
        match_mp_tac deBruijn_subst_check_freevars2>>
        full_simp_tac(srw_ss())[Abbr`ls`,LENGTH_COUNT_LIST]>>
        full_simp_tac(srw_ss())[EVERY_MAP,EVERY_MEM,MEM_COUNT_LIST]>>srw_tac[][]>>
        `st.next_uvar+ n' ∈ FDOM s` by 
          full_simp_tac(srw_ss())[SUBSET_DEF]>>
        metis_tac[check_t_to_check_freevars])
     >>
     (qexists_tac`[]`>>full_simp_tac(srw_ss())[COUNT_LIST_def,infer_deBruijn_subst_id,deBruijn_subst_id]>>
      full_simp_tac(srw_ss())[COUNT_LIST_def,infer_deBruijn_subst_id,sub_completion_def]>>
      full_simp_tac(srw_ss())[check_menv_def,FEVERY_ALL_FLOOKUP]>>
      res_tac>>
      imp_res_tac ALOOKUP_MEM>>
      full_simp_tac(srw_ss())[EVERY_MEM,FORALL_PROD]>>
      metis_tac[]))
 >-
 (* Tup *)
     (`?ts env. v' = (ts,env)` by (PairCases_on `v'` >> metis_tac []) >>
     `t_wfs s` by metis_tac [sub_completion_wfs, infer_e_wfs, pure_add_constraints_wfs] >>
     srw_tac[] [t_walkstar_eqn1, convert_t_def, Tref_def] >>
     metis_tac [MAP_MAP_o])
 >-
 (* Con *)
     (`?tvs ts t. v' = (tvs, ts, t)` by (PairCases_on `v'` >> srw_tac[] []) >>
     srw_tac[] [] >>
     full_simp_tac(srw_ss()) [] >>
     `t_wfs s` by metis_tac [sub_completion_wfs, infer_e_wfs, pure_add_constraints_wfs] >>
     srw_tac[] [convert_t_def, t_walkstar_eqn1, MAP_MAP_o, combinTheory.o_DEF,
         EVERY_MAP, LENGTH_COUNT_LIST] >-
     metis_tac [sub_completion_check] >>
     `type_es tenvM cenv tenv es (MAP (convert_t o t_walkstar s) ts'')`
             by (imp_res_tac sub_completion_add_constraints >>
                 `sub_completion (num_tvs tenv) st'''.next_uvar st'''.subst
                        (ZIP
                           (ts'',
                            MAP
                              (infer_type_subst
                                 (ZIP
                                    (tvs,
                                     MAP (λn. Infer_Tuvar (st'''.next_uvar + n))
                                       (COUNT_LIST (LENGTH tvs))))) ts) ++
                         extra_constraints) s`
                                   by metis_tac [sub_completion_more_vars] >>
                 imp_res_tac sub_completion_infer_es >>
                 metis_tac []) >>
     `t_wfs st'''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac pure_add_constraints_apply >>
     pop_assum (fn _ => all_tac) >>
     pop_assum (fn _ => all_tac) >>
     pop_assum mp_tac >>
     srw_tac[] [MAP_ZIP] >>
     `t_wfs st'.subst` by metis_tac [pure_add_constraints_wfs] >>
     `MAP (t_walkstar s) ts'' =
       MAP (t_walkstar s)
         (MAP
            (infer_type_subst
               (ZIP
                  (tvs,
                   MAP (λn. Infer_Tuvar (st'''.next_uvar + n))
                     (COUNT_LIST (LENGTH tvs))))) ts)`
                 by metis_tac [sub_completion_apply_list] >>
     pop_assum mp_tac >>
     srw_tac[] [subst_infer_subst_swap] >>
     `EVERY (check_freevars 0 tvs) ts` by metis_tac [check_cenv_lookup] >>
     metis_tac [convert_t_subst, LENGTH_COUNT_LIST, LENGTH_MAP,
                MAP_MAP_o, combinTheory.o_DEF])
 >-
 (* Fun *)
     (`t_wfs s ∧ t_wfs st'.subst` by metis_tac [infer_st_rewrs,sub_completion_wfs, infer_e_wfs] >>
     srw_tac[] [t_walkstar_eqn1, convert_t_def, Tfn_def] >>
     imp_res_tac infer_e_next_uvar_mono >>
     full_simp_tac(srw_ss()) [] >>
     `st.next_uvar < st'.next_uvar` by decide_tac >|
     [full_simp_tac(srw_ss()) [sub_completion_def, SUBSET_DEF] >>
          metis_tac [check_t_to_check_freevars],
      `tenv_inv s
                 ((x,0,Infer_Tuvar st.next_uvar)::env) 
                 (bind_tenv x 0 
                            (convert_t (t_walkstar s (Infer_Tuvar st.next_uvar))) 
                            tenv)`
             by (match_mp_tac tenv_inv_extend0 >>
                 full_simp_tac(srw_ss()) []) >>
          full_simp_tac(srw_ss()) [bind_tenv_def] >>
          `check_t 0 (count (st with next_uvar := st.next_uvar + 1).next_uvar) (Infer_Tuvar st.next_uvar)`
                     by srw_tac[] [check_t_def] >>
          `check_env (count (st with next_uvar := st.next_uvar + 1).next_uvar) env`
                     by (srw_tac[] [] >>
                         metis_tac [check_env_more, DECIDE ``x ≤ x + 1:num``]) >>
          first_x_assum match_mp_tac>>
          HINT_EXISTS_TAC>>
          qexists_tac`st with next_uvar := st.next_uvar +1`>>
          full_simp_tac(srw_ss())[num_tvs_def]>>
          metis_tac[]])
 >-
 (* App *)
     (`?c. sub_completion (num_tvs tenv) st''.next_uvar st''.subst c s` 
           by metis_tac [constrain_op_sub_completion] >>
     res_tac >>
     metis_tac [constrain_op_sound, infer_e_wfs])
 >-
 (* Log *)
     binop_tac
 >-
 (* Log *)
     binop_tac
 >-
 (* If *)
     binop_tac
 >-
 (* If *)
     (imp_res_tac sub_completion_unify2 >>
     imp_res_tac sub_completion_infer >>
     imp_res_tac sub_completion_infer >>
     full_simp_tac(srw_ss()) [] >>
     imp_res_tac sub_completion_unify2 >>
     `type_e tenvM cenv tenv e (convert_t (t_walkstar s t1))`
             by metis_tac [] >>
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac t_unify_apply >>
     `t_wfs s'`  by metis_tac [t_unify_wfs] >>
     imp_res_tac sub_completion_apply >>
     `t_wfs s` by metis_tac [sub_completion_wfs] >>
     full_simp_tac(srw_ss()) [t_walkstar_eqn, t_walk_eqn, convert_t_def])
 >-
 (* If *)
     (`t_wfs (st'' with subst := s').subst` 
                by (srw_tac[] [] >>
                    metis_tac [t_unify_wfs, infer_e_wfs]) >>
     `st.next_uvar ≤ (st'' with subst := s').next_uvar` 
                by (imp_res_tac infer_e_next_uvar_mono >>
                    full_simp_tac(srw_ss()) [] >>
                    decide_tac) >>
     `check_env (count (st'' with subst := s').next_uvar) env` 
                by (metis_tac [check_env_more]) >>
     `?ts. sub_completion (num_tvs tenv) st'''''.next_uvar st'''''.subst ts s` 
               by metis_tac [sub_completion_unify2] >>
     imp_res_tac sub_completion_infer >>
     metis_tac [])
  >-
 (* If *)
     (`t_wfs (st'' with subst := s').subst` 
                by (srw_tac[] [] >>
                    metis_tac [t_unify_wfs, infer_e_wfs]) >>
     `t_wfs st''''.subst ∧ t_wfs st'''''.subst ∧ t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     `st.next_uvar ≤ st''''.next_uvar` 
                by (imp_res_tac infer_e_next_uvar_mono >>
                    full_simp_tac(srw_ss()) [] >>
                    decide_tac) >>
     `check_env (count st''''.next_uvar) env` by metis_tac [check_env_more] >>
     `?ts. sub_completion (num_tvs tenv) st'''''.next_uvar st'''''.subst ts s` 
               by metis_tac [sub_completion_unify2] >>
     `type_e tenvM cenv tenv e'' (convert_t (t_walkstar s t3))` by metis_tac [] >>
     imp_res_tac t_unify_apply >>
     `t_wfs s''` by metis_tac [t_unify_wfs] >>
     imp_res_tac sub_completion_apply >>
     metis_tac [])
  >-
 (* Match *)
     (`?ts. sub_completion (num_tvs tenv) st''.next_uvar st''.subst  ts s` 
              by (imp_res_tac sub_completion_infer_pes >>
                  full_simp_tac(srw_ss()) [] >>
                  metis_tac [sub_completion_more_vars]) >>
     `type_e tenvM cenv tenv e (convert_t (t_walkstar s t1))` by metis_tac [] >>
     qexists_tac `convert_t (t_walkstar s t1)` >>
     srw_tac[] [RES_FORALL] >>
     `?p e. x = (p,e)` by (PairCases_on `x` >> metis_tac []) >>
     srw_tac[] [] >>
     `t_wfs (st'' with next_uvar := st''.next_uvar + 1).subst`
              by (srw_tac[] [] >>
                  metis_tac [infer_e_wfs]) >>
     `st.next_uvar ≤ (st'' with next_uvar := st''.next_uvar + 1).next_uvar`
              by (srw_tac[] [] >>
                  imp_res_tac infer_e_next_uvar_mono >>
                  full_simp_tac(srw_ss()) [] >>
                  decide_tac) >>
     `check_env (count (st'' with next_uvar := st''.next_uvar + 1).next_uvar) env` by metis_tac [check_env_more] >>
     `type_pes tenvM cenv tenv pes (convert_t (t_walkstar s t1)) (convert_t (t_walkstar s (Infer_Tuvar st''.next_uvar)))`
              by metis_tac [] >>
     full_simp_tac(srw_ss()) [type_pes_def, RES_FORALL] >>
     pop_assum (mp_tac o Q.SPEC `(p,e')`) >>
     srw_tac[] [])
 >-
 (* Let *)
     (* COMPLETENESS disj2_tac >>*)
     (imp_res_tac sub_completion_infer >>
     full_simp_tac(srw_ss()) [] >>
     imp_res_tac sub_completion_unify >>
     qexists_tac `convert_t (t_walkstar s t1)` >>
     srw_tac[] [] >-
     metis_tac [] >>
     `t_wfs st''.subst` by metis_tac [infer_e_wfs] >>
     imp_res_tac t_unify_wfs >>
     `tenv_inv s (opt_bind x (0,t1) env) 
                 (opt_bind_tenv x 0 (convert_t (t_walkstar s t1)) tenv)` 
            by (cases_on `x` >>
                full_simp_tac(srw_ss()) [opt_bind_def, opt_bind_tenv_def, GSYM bind_tenv_def] >>
                match_mp_tac tenv_inv_extend0 >>
                metis_tac[sub_completion_wfs])>>
     `num_tvs (opt_bind_tenv x 0 (convert_t (t_walkstar s t1)) tenv) = num_tvs tenv` 
            by (cases_on `x` >>
                srw_tac[] [opt_bind_tenv_def] >>
                srw_tac[] [num_tvs_def, bind_tenv_def]) >>
     `check_t 0 (count st''.next_uvar) t1` by metis_tac [infer_e_check_t] >>
     `check_env (count st''.next_uvar) env` by metis_tac [infer_e_next_uvar_mono, check_env_more] >>
     `check_env (count st''.next_uvar) (opt_bind x (0,t1) env)` 
               by (cases_on `x` >>
                   full_simp_tac(srw_ss()) [opt_bind_def, check_env_def]) >>
     metis_tac [])
 >-
 (* Letrec *)
     (`t_wfs (st with next_uvar := st.next_uvar + LENGTH funs).subst`
               by srw_tac[] [] >>
     Q.ABBREV_TAC `env' = MAP2 (λ(f,x,e) uvar. (f,0:num,uvar)) funs (MAP (λn. Infer_Tuvar (st.next_uvar + n)) (COUNT_LIST (LENGTH funs)))` >>
     Q.ABBREV_TAC `tenv' = MAP2 (λ(f,x,e) t. (f,t)) funs (MAP (λn. convert_t (t_walkstar s (Infer_Tuvar (st.next_uvar + n)))) (COUNT_LIST (LENGTH funs)))` >>
     `sub_completion (num_tvs (bind_var_list 0 tenv' tenv)) st'.next_uvar st'.subst extra_constraints s`
                 by metis_tac [num_tvs_bind_var_list] >>
     `?constraints1. sub_completion (num_tvs (bind_var_list 0 tenv' tenv)) st''''.next_uvar st''''.subst constraints1 s`
                 by metis_tac [sub_completion_infer] >>
     `?constraints2. sub_completion (num_tvs (bind_var_list 0 tenv' tenv)) st'''.next_uvar st'''.subst constraints2 s`
                 by metis_tac [sub_completion_add_constraints] >>
     `tenv_inv s (env' ++ env) (bind_var_list 0 tenv' tenv)` 
                 by (UNABBREV_ALL_TAC >>
                     match_mp_tac tenv_inv_letrec_merge >>full_simp_tac(srw_ss())[]>>
                     imp_res_tac infer_e_wfs>>
                     full_simp_tac(srw_ss())[]>>rev_full_simp_tac(srw_ss())[]>>
                     metis_tac[pure_add_constraints_wfs,sub_completion_wfs])>>
     `check_env (count (st with next_uvar := st.next_uvar + LENGTH funs).next_uvar) (env' ++ env)`
                 by (srw_tac[] [check_env_merge] >|
                     [Q.UNABBREV_TAC `env'` >>
                          srw_tac[] [check_env_letrec_lem],
                      metis_tac [check_env_more, DECIDE ``x ≤ x+y:num``]]) >>
     `type_funs tenvM cenv (bind_var_list 0 tenv' tenv) funs 
                (MAP2 (\(x,y,z) t. (x, convert_t (t_walkstar s t))) funs funs_ts)`
                 by metis_tac [] >>
     `t_wfs st''''.subst` by metis_tac [infer_e_wfs, pure_add_constraints_wfs] >>
     `st.next_uvar + LENGTH funs ≤ st''''.next_uvar`
                 by (full_simp_tac(srw_ss()) [] >>
                     imp_res_tac infer_e_next_uvar_mono >>
                     full_simp_tac(srw_ss()) [] >>
                     metis_tac []) >>
     full_simp_tac(srw_ss()) [] >>
     `type_e tenvM cenv (bind_var_list 0 tenv' tenv) e (convert_t (t_walkstar s t))`
                 by metis_tac [check_env_more] >>
     qexists_tac `tenv'` >>
     (* COMPLETENESS qexists_tac `0` >>*)
     srw_tac[] [bind_tvar_def] >>
     `tenv' = MAP2 (λ(x,y,z) t. (x,convert_t (t_walkstar s t))) funs funs_ts`
                 by (Q.UNABBREV_TAC `tenv'` >>
                     match_mp_tac letrec_lemma >>
                     imp_res_tac infer_e_wfs >>
                     imp_res_tac pure_add_constraints_apply >>
                     `LENGTH funs = LENGTH funs_ts` by metis_tac [LENGTH_COUNT_LIST] >>
                     full_simp_tac(srw_ss()) [GSYM MAP_MAP_o, MAP_ZIP, LENGTH_COUNT_LIST, LENGTH_MAP] >>
                     metis_tac [MAP_MAP_o, combinTheory.o_DEF, sub_completion_apply_list]) >>
     srw_tac[] [])
 >-
 metis_tac [sub_completion_infer_es]
 >-
 metis_tac [infer_e_wfs, infer_e_next_uvar_mono, check_env_more]
 >-
 srw_tac[] [type_pes_def, RES_FORALL]
 >-
 (`?t env. v' = (t,env)` by (PairCases_on `v'` >> metis_tac []) >>
     srw_tac[] [] >>
     `∃ts. sub_completion (num_tvs tenv) (st'''' with subst:= s'').next_uvar (st'''' with subst:= s'').subst ts s` 
                   by metis_tac [sub_completion_infer_pes] >>
     full_simp_tac(srw_ss()) [] >>
     `∃ts. sub_completion (num_tvs tenv) st''''.next_uvar st''''.subst ts s` 
              by metis_tac [sub_completion_unify2] >>
     `∃ts. sub_completion (num_tvs tenv) (st'' with subst := s').next_uvar (st'' with subst := s').subst ts s` 
              by metis_tac [sub_completion_infer] >>
     full_simp_tac(srw_ss()) [] >>
     `∃ts. sub_completion (num_tvs tenv) st''.next_uvar st''.subst ts s` 
              by metis_tac [sub_completion_unify2] >>
     `type_p (num_tvs tenv) cenv p (convert_t (t_walkstar s t)) (convert_env s env')`
              by metis_tac [infer_p_sound] >>
     `t_wfs (st'' with subst := s').subst`
           by (srw_tac[] [] >>
               metis_tac [infer_p_wfs, t_unify_wfs]) >>
     imp_res_tac infer_p_check_t >>
     `check_env (count (st'' with subst:=s').next_uvar) (MAP (λ(n,t). (n,0,t)) (SND (t,env')) ++ env)`
           by (srw_tac[] [check_env_merge] >|
               [srw_tac[] [check_env_def, EVERY_MAP, remove_pair_lem] >>
                    full_simp_tac(srw_ss()) [EVERY_MEM] >>
                    srw_tac[] [] >>
                    PairCases_on `x` >>
                    full_simp_tac(srw_ss()) [] >>
                    res_tac >>
                    full_simp_tac(srw_ss()) [],
                metis_tac [infer_p_next_uvar_mono, check_env_more]]) >>
     `tenv_inv s (MAP (λ(n,t). (n,0,t)) env' ++ env) (bind_var_list 0 (convert_env s env') tenv)` 
              by (
              match_mp_tac tenv_inv_merge>>full_simp_tac(srw_ss())[]>>
              metis_tac[sub_completion_wfs])>>
     `type_e tenvM cenv (bind_var_list 0 (convert_env s env') tenv) e (convert_t (t_walkstar s t2'))`
               by metis_tac [check_env_merge, SND, num_tvs_bind_var_list] >>
     srw_tac[] [type_pes_cons] >|
     [imp_res_tac infer_p_bindings >>
          metis_tac [APPEND_NIL],
      qexists_tac `(convert_env s env')` >>
           srw_tac[] [] >>
           imp_res_tac infer_p_wfs >>
           imp_res_tac infer_e_wfs >>
           imp_res_tac t_unify_apply >>
           metis_tac [t_unify_wfs, sub_completion_apply],
      `t_wfs (st'''' with subst := s'').subst`
           by (srw_tac[] [] >>
               metis_tac [t_unify_wfs, infer_e_wfs]) >>
          `(st.next_uvar ≤ (st'''' with subst := s'').next_uvar)` 
                  by (full_simp_tac(srw_ss()) [] >>
                      imp_res_tac infer_p_next_uvar_mono >>
                      imp_res_tac infer_e_next_uvar_mono >>
                      full_simp_tac(srw_ss()) [] >>
                      decide_tac) >>
          `check_env (count (st'''' with subst := s'').next_uvar) env` by metis_tac [check_env_more] >>
          metis_tac []])
 >>
 `t_wfs st'''.subst ∧ t_wfs (st with next_uvar := st.next_uvar + 1).subst` by metis_tac [infer_e_wfs, infer_st_rewrs] >>
     imp_res_tac sub_completion_infer_funs >>
     `tenv_inv s ((x,0,Infer_Tuvar st.next_uvar)::env) (bind_tenv x 0 (convert_t (t_walkstar s (Infer_Tuvar st.next_uvar))) tenv)`
              by (match_mp_tac tenv_inv_extend0 >>
                  full_simp_tac(srw_ss())[]>>metis_tac[sub_completion_wfs])>>
     `num_tvs (bind_tenv x 0 (convert_t (t_walkstar s (Infer_Tuvar st.next_uvar))) tenv) = num_tvs tenv`
              by full_simp_tac(srw_ss()) [num_tvs_def, bind_tenv_def] >>
     `check_env (count (st with next_uvar := st.next_uvar + 1).next_uvar) env ∧
      check_t 0 (count (st with next_uvar := st.next_uvar + 1).next_uvar) (Infer_Tuvar st.next_uvar)`
                by (srw_tac[] [check_t_def] >>
                    metis_tac [check_env_more, DECIDE ``x ≤ x + 1:num``]) >>
     `type_e tenvM cenv (bind_tenv x 0 (convert_t (t_walkstar s (Infer_Tuvar st.next_uvar))) tenv)
             e (convert_t (t_walkstar s t))`
                 by metis_tac [] >>
     `check_env (count st'''.next_uvar) env`
                 by (metis_tac [check_env_more, infer_e_next_uvar_mono]) >>
     `type_funs tenvM cenv tenv funs (MAP2 (\(x,y,z) t. (x, convert_t (t_walkstar s t))) funs ts')`
               by metis_tac [] >>
     `t_wfs s` by metis_tac [sub_completion_wfs] >>
     srw_tac[] [t_walkstar_eqn1, convert_t_def, Tfn_def] >|
     [srw_tac[] [check_freevars_def] >>
          match_mp_tac check_t_to_check_freevars >>
          srw_tac[] [] >>
          full_simp_tac(srw_ss()) [sub_completion_def] >|
          [`st.next_uvar < st'''.next_uvar`
                    by (imp_res_tac infer_e_next_uvar_mono >>
                        full_simp_tac(srw_ss()) [] >>
                        decide_tac) >>
               `st.next_uvar ∈ FDOM s`
                    by full_simp_tac(srw_ss()) [count_def, SUBSET_DEF] >>
               metis_tac [],
           match_mp_tac (hd (CONJUNCTS check_t_walkstar)) >>
               srw_tac[] [] >>
               `check_t 0 (count (st'''.next_uvar)) t`
                         by (imp_res_tac infer_e_check_t >>
                             full_simp_tac(srw_ss()) [check_env_bind]) >>
               metis_tac [check_t_more5]],
      imp_res_tac infer_funs_length >>
          srw_tac[] [ALOOKUP_FAILS, MAP2_MAP, MEM_MAP, MEM_ZIP] >>
          PairCases_on `y` >>
          full_simp_tac(srw_ss()) [MEM_MAP, MEM_EL] >>
          metis_tac [FST]]);

val _ = export_theory ();
