
/* Main Script for preparing the Dataset

/*--------------- PART I 
	 Prepare Dataset on Vocatioanl education of Indivudals */

			clear										
			set more off								
			capture log close
			log using "Z:\Projects\<CENSORED_PATH>\ML\Merging\data_creation_process"
			cd "Z:\SUF\On-Site\SC4\SC4_O_12-0-0\Stata14" 	/*-->edit onsite*/

			use SC4_spVocTrain_O_12-0-0.dta				  	/*-->edit onsite; "R"="O"*/
			count
			duplicates report ID_t
			
	/*create DV: Type of training/schooling*/
			gen train_school=1 if ts15201==1
			recode train_school .=2 if ts15201==2
			recode train_school .=2 if ts15201==3
			recode train_school .=2 if ts15201==4
			recode train_school .=3 if ts15201==6
			recode train_school .=3 if ts15201==7
			recode train_school .=3 if ts15201==8
			recode train_school .=3 if ts15201==9
			recode train_school .=3 if ts15201==10

			label var train_school "Type of training/schooling"
			label define ttrain 0 "general school" 1 "dual VET" 2 "school-based VET" 3 "academic training" 4 "interdediate value"
			label values train_school ttrain

	/*create year &  month variable*/
			gen start_year=ts1511y_g1
			gen start_month=ts1511m_g1
			label var start_year "Start Year"
			label var start_month "Start Month"

			gen end_year=ts1512y_g1
			gen end_month=ts1512m_g1
			label var end_year "End Year"
			label var end_month "End Month"

			gen still_valid=ts1512c_g1
			label var still_valid "Episode continues"

	/*keep relevant variables from the SC4_spVocTrain*/
			keep train_school ID_t splink subspell spell wave ts15201 ts15207_g4O ts1511m_g1 ts1511y_g1 start_year start_month end_year end_month still_valid

	/*save SC4_spVocTrain data*/
			save "Z:\Projects\<CENSORED_PATH>\ML\Merging\SC4_v12_VET.dta", replace

/*--------------- PART II 
	 Add additonal Data Source like School */

	 /*add school info from SC4_spSchool*/
			use "SC4_spSchool_O_12-0-0.dta"

	/*drop primary school*/
			drop if ts11204<4
			


	/*create year variable*/
			gen start_year=ts1111y_g1
			label var start_year "Start Year"
			gen start_month=ts1111m_g1
			label var start_month "Start Month"

			gen end_year=ts1112y_g1 
			label var end_year "End Year"
			gen end_month=ts1112m_g1
			label var end_month "End Month"
			
			gen still_valid=tf1112c_g1
			label var still_valid "Episode continues"
			
	/*keep relevant variables*/
			keep ID_t splink subspell spell wave tf1112c tf11211 ts11202_g4O ts11204  ts11205 ts11207 ts11209  ts11206_O tf1112c_g1 ts1112m_g1 ts1112y_g1 tf11218 ts11227 ts11228 ts11229 ts11230 start_year start_month end_year end_month still_valid

			count
			duplicates report ID_t

	/*merge SC4_spSchool and SC4_v12_VET*/
			merge 1:1 ID_t subspell splink wave start_year start_month using "Z:\Projects\<CENSORED_PATH>\ML\Merging\SC4_v12_VET.dta"

			count
			duplicates report ID_t
			
	/*delete missings DV from using data that comes from spVocTrain*/
			drop if train_school==. & _merge==2

			count
			duplicates report ID_t
	
	/*create general school leaving diploma*/
			gen school_dipl = 0 if ts11209==1
			recode school_dipl .=0 if ts11209==2
			recode school_dipl .=1 if ts11209==3
			recode school_dipl .=2 if ts11209==4
			recode school_dipl .=2 if ts11209==5

			label var school_dipl "school leaving diploma"
			label define school 0 "lower sec. (HS)" 1 "interm. sec. (RS)" 2 "high sec. (Abi)" 3 "interm. sec. (Gym)"
			label values school_dipl school

	/*recode train_school with general school information -> We will later differentiate between different types*/
			/*recode train_school .= 2 if ts11204>0 & train_school==. & ts11204 == 13*/
			
			recode train_school .= 2 if ts11204==8 & ts11207 == 1  /*Gymnasien an denen eine (self-Reported) Ausbildung gemacht werden kann */
			recode train_school .= 2 if ts11204==13 & ts11207 == 1 /*Beruflcihe Schulen an denen eine (self-Reported)  Ausbildung gemacht werden kann */
			recode train_school .= 2 if ts11204==14 & ts11207 == 1 /*andere Schulen an denen eine (self-Reported)  Ausbildung gemacht werden kann */
			recode train_school .= 4 if ts11204==8 & ts11205 != 11  /* Gymnasien die keine Allgemeinbildenen Gymnasien Sind werden auf itermediate gesetzt.... später wird überprüft ob Zeitgleich eine betriebliche Ausbildung stattfindet*/
			recode train_school .= 4 if ts11204==13
			recode train_school .= 4 if ts11204==14
			recode train_school .= 0 if ts11204>0 

			drop if ts11205 == -96
/****  Clean Episodes *****/				
			
	/* Order Episodes and create ranking */		
	
		drop if start_month <1 
		drop if start_year < 2000
		gen start_ym  = start_year*100+start_month
		
		drop if end_month <1 & still_valid == 2
		drop if end_year < 2000 & still_valid == 2
		gen end_ym  = end_year*100+end_month  if still_valid ==2
		gen neg_still_valid = - still_valid
	
	/* Delete Episodes with updated information from later wave */
	    
		gsort ID_t start_ym train_school neg_still_valid -end_ym -wave spell
		duplicates tag ID_t start_ym train_school ts11204 ts15201, generate (duplicate) /*just for controlling that the right ones are deleted */
		duplicates drop ID_t start_ym train_school ts11204 ts15201, force 

		count
		duplicates report ID_t
		
		
	/* Delete Episodes shorter than 6 months **/
	
		drop if end_ym - start_ym < 6
		
		count
		duplicates report ID_t
		
	/* Select Episodes that are part of spVoc AND spSchool and therefore doubled with different values */
	
		egen rank_old = rank(-still_valid), by(ID_t start_ym) /**Duplicated entries per person with different variable values **/
		sort ID_t start_ym train_school 
		by ID_t start_ym: gen keep_dual = 1 if rank_old == 1.5 & train_school == 1  /** if Dual Vet and School based Vet started at the same time <- it is a dual vet **/
		
		/***/
		gen neg_school_dipl = -school_dipl
		sort ID_t start_ym neg_school_dipl
		egen rank_edu = rank(school_dipl), by(ID_t start_ym) 
		recode keep_dual .= 1 if rank_old == 1.5 & rank_edu ==2 /** If two certificates where done on the same school, keep the highest one **/		
		

		/***/
		egen rank_train = rank(train_school), by(ID_t start_ym train_school) 
		egen rank_train_end = rank(-end_ym), by(ID_t start_ym train_school) 
		recode keep_dual .= 1 if rank_old == 1.5 & rank_train == 1.5 & rank_train_end ==1 /** If two same entries exists, take the one ending later **/		
		/***/
		
	
		recode keep_dual .= 0 if rank_old == 1.5
		drop if keep_dual == 0
		
				
		drop rank_train keep_dual rank_old neg_school_dipl rank_train_end neg_still_valid
		
		count
		duplicates report ID_t
		
/****  Analyse Episodes *****/	
	/*write information in same line as school diploma*/
			gsort ID_t start_ym train_school
			by ID_t: gen train = train_school[_n+1] 
			label var train "Transition to"
			label values train ttrain

	/*write information in same line as school diploma + 1 transition*/
			gsort ID_t start_year start_month train_school
			by ID_t: gen train_2 = train_school[_n+2] 
			label var train_2 "Transition to"
			label values train_2 ttrain
			
	/*create year variable that marks beginn of train*/
			gsort ID_t start_year start_month train_school
			by ID_t: gen start_year_train = start_year[_n+1] 
			label var start_year_train "year beginning VET/HE"
	
	/*create month variable that marks beginn of train*/
			gsort ID_t start_year start_month train_school
			by ID_t: gen start_month_train = start_month[_n+1] 
			label var start_month_train "month beginning VET/HE"
	
	/*create variable that marks start of train*/
			gsort ID_t start_year start_month train_school
			by ID_t: gen start_ym_train = start_ym[_n+1] 
	
	/*createh variable that marks end of train*/
			gsort ID_t start_year start_month 
			by ID_t: gen end_ym_train = end_ym[_n+1] 
	
			
	/*create variable that marks start of train_2*/
			gsort ID_t start_year start_month train_school
			by ID_t: gen start_ym_train_2 = start_ym[_n+2] 
	
	/*createh variable that marks end of train_2*/
			gsort ID_t start_year start_month  train_school
			by ID_t: gen end_ym_train_2 = end_ym[_n+2] 		
		
			
    /***** Check for overlapping episodes e.g. if the start of 2nd episode is in between start and end of 1st within 1 year from start****/
			gen overlap =1 if start_ym_train_2 >= start_ym_train & end_ym_train > start_ym_train_2 & start_ym_train_2 < (start_ym_train + 100) & start_ym_train_2 < (end_ym_train -3)
			
			sort overlap train train_2
			
	/***** Recode intermediates dependent on overlaps ****/
	
			recode train (0=2) if train == 0 & train_2 == 2 & overlap == 1  
			recode train (2=1) if train == 2 & train_2 == 1 & overlap == 1
			
			recode train (4=1) if train == 4 & train_2 == 1 & overlap == 1
			recode train (4=1) if train == 4 & train_2 == 1 & overlap == 1
			recode train (4=2) if train == 4 & train_2 == 2 & overlap == 1

			recode train (4=0)
			
			drop train_2 start_ym_train_2 end_ym_train_2 overlap					
	    	drop if train ==.
			
	/*keep first diploma and all following transition*/
			sort ID_t start_year_train
			egen rank = rank(school_dipl), by(ID_t)
			keep if rank<2

	/*keep data, where 2 transitions where made in the same year */
			egen rank_switch = rank(start_year_train), by(ID_t)
			keep if rank_switch<2		

	/*keep the later transition for the same year */
			egen rank_switch_2 = rank(-start_year_train), by(ID_t)
			keep if rank_switch_2<2	
	
			count
		    duplicates report ID_t
			
	/*reverse grades and delete missings*/
			drop if tf11218 <0
			gen grade=6-tf11218
			label var grade "final school grades (GPA)"

			count
		    duplicates report ID_t
	/* Cut off Abiturients */	
			gen year_substract=3 if school_dipl==2
			recode year_substract .= 0 
			gen year_train_adapted = start_year_train - year_substract
			drop start_year_train year_substract
			gen start_year_train = year_train_adapted
			label var start_year_train "year beginning VET/HE"

			drop year_train_adapted
			
			recode train (1=0)(2=0)(3=0)(4=0) if school_dipl == 2
			
			recode school_dipl (1=3) if ts11204 == 8
			recode school_dipl (2=3) if school_dipl == 2


	/*drop irrelevant variables*/
			drop tf1112c tf11211 ts11204 tf11218 ts1112m_g1 ts1112y_g1 ts1511y_g1 _merge tf1112c_g1 ts11209 ts1511m_g1 rank	ts11227 ts11228 ts11229 ts11230 train_school rank rank_switch rank_switch_2 start_ym_train end_ym_train start_ym end_ym _merge

		    duplicates drop ID_t, force 

			
			count
		    duplicates report ID_t
		
			/*save dataset with DV and school vars*/
			save "Z:\Projects\<CENSORED_PATH>\ML\Merging\SC4_v12_VET_school.dta", replace
			
			
			count
		    duplicates report ID_t
			
/*--------------- PART III 
 Add additonal Data on Parents*/			
					
	/*merge with target data set to add control variables*/
		merge 1:m ID_t using "SC4_pTarget_O_12-0-0.dta"

		count
		duplicates report ID_t
		
	/*parents education*/
		gen parent_edu = 2 if t731370>3 
		recode parent_edu .=1 if t731320>3
		recode parent_edu .=1 if t731370==3 
		recode parent_edu .=1 if t731320==3
		recode parent_edu .=1 if t731370==2 
		recode parent_edu .=1 if t731320==2
		recode parent_edu .=0 if t731370==1 
		recode parent_edu .=0 if t731320==1
		recode parent_edu .=0 if t731370==0 
		recode parent_edu .=0 if t731320==0
		label var parent_edu "parents education (max.)"
		label define pareduc 0 "low" 1 "intermediate" 2 "high"
		label values parent_edu pareduc
	/*low= no school dipl or HS, interm.=RS or ABI (without HE), high=HE or phD*/

		gen mother_aca =0 if t731422_g4>2999
		recode mother_aca .=1 if t731422_g4>0
		gen father_aca =0 if t731472_g4>2999
		recode father_aca .=1 if t731472_g4>0

		/*parents occupation*/
		egen parent_aca = rowmax (father_aca mother_aca)
		
		label var parent_aca "parents occupation"
		label def paca 0 "non-academic occupation" 1 "academic occupation"
		label values parent_aca paca

		/*migration background*/
		gen migback = 1 if t400500_g3R>1
		recode migback .=0 if t400500_g3R==1
		label var migback "migration background"
		label def mig 0 "native german" 1 "migration background"
		label values migback mig

		/*sex*/
		gen sex=0 if t700031==2 
		recode sex .=1 if t700031==1
		label var sex "sex"
		label def gender 0 "female" 1 "male"
		label values sex gender

		/*personality*/
		/*recode missings, keep variables as they are*/
		nepsmiss t66800e_g1 t66800d_g1 t66800c_g1 t66800b_g1 t66800a_g1

		/*peer VET plans*/
		/*recode missings, keep variable as is*/
		tab t32111d
		nepsmiss t32111d

		/*keep only one row per ID*/
		duplicates drop ID_t, force 

		/*keep variables*/
		keep  ID_t splink subspell spell wave ts11202_g4O start_year start_month ts15207_g4O  school_dipl train start_year_train grade tx44401_g4O t66800e_g1 t66800d_g1 t66800c_g1 t66800b_g1 t66800a_g1 t32111d parent_edu parent_aca migback sex 

		/*drop missing values in variables*/
		drop if train==.
		drop if grade==.
		drop if parent_edu==.
		drop if parent_aca ==.
		drop if migback==.
		drop if sex==.
		drop if start_year_train<0
		drop if school_dipl==.
        
		count
		duplicates report ID_t

		save  "Z:\Projects\<CENSORED_PATH>\ML\Merging\SC4_v12_VET_school_indi.dta", replace
		
		
/*--------------- PART IV
 Add Controls for class school*/	
 		merge 1:m ID_t using "Z:\Projects\<CENSORED_PATH>\ML\Merging\school_grades" 	
		
		count
		duplicates report ID_t
		
		drop if _merge==2
		drop if _merge==1
		/*keep variables*/
		
		keep  ID_t splink subspell spell wave ts11202_g4O start_year start_month school_dipl train start_year_train grade t66800e_g1 t66800d_g1 t66800c_g1 t66800b_g1 t66800a_g1 parent_edu parent_aca migback sex ID_i 

		/*drop missing values in variables*/
		drop if ID_i==.
		drop if ID_i==-54
		drop if ID_i==-99
		
		
		count
		duplicates report ID_t
		
			save  "Z:\Projects\<CENSORED_PATH>\ML\Merging\SC4_v12_VET_school_indi_control.dta", replace

/*--------------- PART IV 
 Add Regional Indicators*/				
		merge m:1 ts11202_g4O using "Z:\Projects\<CENSORED_PATH>\ML\Daten\InIoe13\InIoe13.dta"
		drop if _merge==2
		drop if _merge==1
		drop if train == 3
		
		sort ID_t
		duplicates tag ID_t, generate (duplicate)
		duplicates drop ID_t, force 


		count
		duplicates report ID_t
		
		save  "Z:\Projects\<CENSORED_PATH>\ML\Merging\SC4_v12_VET_school_indi_regio.dta", replace

		log close

/*Analyses

MODEL: Multinomial logit/probit, base category (1)=dual VET

DV: Type of training/schooling: train - three categories: dual VET, school VET, further school/acaemic training


CONTROLS:
- school diploma (separate models for abitur vs HS und RS): school_dipl
- grades: grade 

- parental educ./occup.: parent_edu, parent_aca
- migration background: migback
- sex: sex
- personality: t66800e_g1 t66800d_g1 t66800c_g1 t66800b_g1 t66800a_g1


REGIONAL:
- unemployment rate 
- types of school leavers (cohort size)
- training places in region
- political preferences (normative culture in region)
- commuting distances
- industrial structure of region (branches, sectors etc.)
- ...


POTENTIAL INTERACTIONS:
- between several regional factors (trial and error)
- parent_edu * several regional factors
- migback * several regional factors
- sex * several regional factors
- school_dipl * several regional factors (or separate models for school diploma)
- */

