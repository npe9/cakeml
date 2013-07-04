(*Generated by Lem from compiler.lem.*)
open bossLib Theory Parse res_quanTheory
open fixedPointTheory finite_mapTheory listTheory pairTheory pred_setTheory
open integerTheory set_relationTheory sortingTheory stringTheory wordsTheory

val _ = numLib.prefer_num();



open ToBytecodeTheory ToIntLangTheory IntLangTheory CompilerPrimitivesTheory BytecodeTheory PrinterTheory CompilerLibTheory SemanticPrimitivesTheory AstTheory LibTheory

val _ = new_theory "Compiler"

(*open SemanticPrimitives*)
(*open Ast*)
(*open CompilerLib*)
(*open IntLang*)
(*open ToIntLang*)
(*open ToBytecode*)
(*open Bytecode*)

val _ = type_abbrev( "contab" , ``: (( conN id), num)fmap # (num # conN id) list # num``);
(*val cmap : contab -> Pmap.map (id conN) num*)
 val cmap_def = Define `
 (cmap (m,_,_) = m)`;


val _ = Hol_datatype `
 compiler_state =
  <| contab : contab
   ; renv : (string # num) list
   ; rmenv : (string, ( (string # num)list))fmap
   ; rsz : num
   ; rnext_label : num
   |>`;


(*val cpam : compiler_state -> list (num * id conN)*)
 val cpam_def = Define `
 (cpam s = ((case s.contab of (_,w,_) => w )))`;


val _ = Define `
 init_compiler_state =  
(<| contab := ( FUPDATE FEMPTY ( (Short ""), tuple_cn)
              ,[(tuple_cn,Short "")]
              ,3)
   ; renv := []
   ; rmenv := FEMPTY
   ; rsz := 0
   ; rnext_label := 0
   |>)`;


 val number_constructors_defn = Hol_defn "number_constructors" `

(number_constructors _ [] ct = ct)
/\
(number_constructors mn ((c,_)::cs) (m,w,n) =  
(number_constructors mn cs ( FUPDATE  m ( (mk_id mn c), n), ((n,mk_id mn c) ::w), (n +1))))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn number_constructors_defn;

 val dec_to_contab_def = Define `

(dec_to_contab mn ct (Dtype ts) = ( FOLDL (\ct p . 
  (case (ct ,p ) of ( ct , (_,_,cs) ) => number_constructors mn cs ct )) ct ts))
/\
(dec_to_contab _ ct _ = ct)`;


 val decs_to_contab_defn = Hol_defn "decs_to_contab" `

(decs_to_contab _ ct [] = ct)
/\
(decs_to_contab mn ct (d::ds) = (decs_to_contab mn (dec_to_contab mn ct d) ds))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn decs_to_contab_defn;

 val compile_news_defn = Hol_defn "compile_news" `

(compile_news _ cs _ [] = ( emit cs [Stack Pop]))
/\
(compile_news print cs i (v::vs) =  
(let cs = ( emit cs ( MAP Stack [Load 0; Load 0; El i])) in
  let cs = (if print then
      let cs = ( emit cs ( MAP PrintC (EXPLODE (CONCAT["val ";v;" = "])))) in
      emit cs [Stack(Load 0); Print]
    else cs) in
  let cs = ( emit cs [Stack (Store 1)]) in
  compile_news print cs (i +1) vs))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn compile_news_defn;

val _ = Define `
 (compile_Cexp menv env rsz cs Ce =  
(let (Ce,nl) = ( label_closures ( LENGTH env) cs.next_label Ce) in
  let cs = ( compile_code_env menv ( cs with<| next_label := nl |>) Ce) in
  compile menv env TCNonTail rsz cs Ce))`;


val _ = Define `
 (compile_fake_exp menv m env rsz cs vs e =  
(let Ce = ( exp_to_Cexp m (e (Con (Short "") ( MAP (\ v . Var (Short v)) vs)))) in
  compile_Cexp menv env rsz cs Ce))`;


 val compile_dec_def = Define `

(compile_dec _ _ _ _ cs (Dtype _) = (NONE, emit cs [Stack (Cons (block_tag +tuple_cn) 0)]))
/\
(compile_dec menv m env rsz cs (Dletrec defs) =  
(let vs = ( MAP (\p . 
  (case (p ) of ( (n,_,_) ) => n )) defs) in
  (SOME vs, compile_fake_exp menv m env rsz cs vs (\ b . Letrec defs b))))
/\
(compile_dec menv m env rsz cs (Dlet p e) =  
(let vs = ( pat_bindings p []) in
  (SOME vs, compile_fake_exp menv m env rsz cs vs (\ b . Mat e [(p,b)]))))`;


 val compile_decs_defn = Hol_defn "compile_decs" `

(compile_decs _ _ ct m _ rsz cs [] = (ct,m,rsz,cs))
/\
(compile_decs mn menv ct m env rsz cs (dec::decs) =  
(let (vso,cs) = ( compile_dec menv m env rsz cs dec) in
  let ct = ( dec_to_contab mn ct dec) in
  let (m,env,rsz,cs) =    
((case vso of
      NONE => ((m with<| cnmap := cmap ct|>),env,rsz,cs)
    | SOME vs =>
        let n = ( LENGTH vs) in
        ((m with<| bvars := vs ++m.bvars|>)
        ,(( GENLIST (\ i . CTDec (rsz +i)) n) ++env)
        ,(rsz + n)
        ,(case mn of NONE => cs | _ => compile_news F cs 0 vs ))
    )) in
  compile_decs mn menv ct m env rsz cs decs))`;

val _ = Lib.with_flag (computeLib.auto_import_definitions, false) Defn.save_defn compile_decs_defn;

val _ = Define `
 (compile_decs_wrap mn rs decs =  
(let cs = (<| out := []; next_label := rs.rnext_label |>) in
  let cs = ( emit cs [PushPtr (Addr 0); PushExc]) in
  let menv = ( (o_f) ( MAP SND) rs.rmenv) in
  let m = (<| bvars := ( MAP FST rs.renv)
           ; mvars := ( (o_f) ( MAP FST) rs.rmenv)
           ; cnmap := ( cmap rs.contab)
           |>) in
  let env = ( MAP ((o) CTDec SND) rs.renv) in
  let (ct,m,rsz,cs) = ( compile_decs mn menv rs.contab m env (rs.rsz +2) cs decs) in
  let n = (rsz - 2 - rs.rsz) in
  let news = ( TAKE n m.bvars) in
  let cs = (if IS_NONE mn then cs else emit cs [Stack (Cons tuple_cn n)]) in
  let cs = ( emit cs [PopExc; Stack(Pops 1)]) in
  let cs = ( compile_news (IS_NONE mn) cs 0 news) in
  let env = ( ZIP ( news, ( GENLIST (\ i . rs.rsz +i) n))) in
  let (renv,rmenv) =    
((case mn of
      NONE => ((env ++rs.renv),rs.rmenv)
    | SOME mn => (rs.renv, FUPDATE  rs.rmenv ( mn, env))
    )) in
  ((rs with<|
     rsz := rs.rsz +n
    ;renv := renv
    ;rmenv := rmenv
    ;rnext_label := cs.next_label
    ;contab := ct
    |>)
  ,cs.out)))`;


 val compile_print_dec_def = Define `

(compile_print_dec (Dtype ts) code = ( FOLDL (\code p . 
  (case (code ,p ) of
      ( code , (_,_,cs) ) => FOLDL
                               (\code p . (case (code ,p ) of
                                              ( code , (c,_) ) =>
                                          ( REVERSE
                                              ( MAP PrintC
                                                  (EXPLODE
                                                     (CONCAT
                                                        [c;" = <constructor>"])))) ++
                                          code
                                          )) code cs
  )) code ts))
/\
(compile_print_dec _ code = code)`;


 val compile_top_def = Define `

(compile_top rs (Tmod mn _ decs) =  
(let (rss,code) = ( compile_decs_wrap (SOME mn) rs decs) in
  let str = ( CONCAT["structure ";mn;" = <structure>"]) in
  (rss
  ,( rs with<|
      contab := rss.contab
    ; rnext_label := rss.rnext_label
    ; rmenv := FUPDATE  rs.rmenv ( mn, []) |>)
  , REVERSE(( REVERSE( MAP PrintC (EXPLODE str))) ++code))))
/\
(compile_top rs (Tdec dec) =  
(let (rss,code) = ( compile_decs_wrap NONE rs [dec]) in
  (rss
  ,( rs with<|
      contab := rss.contab
    ; rnext_label := rss.rnext_label |>)
  , REVERSE(compile_print_dec dec code))))`;

val _ = export_theory()

