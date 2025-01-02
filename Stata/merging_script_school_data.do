
/* Script for computing average school grades and saving it a as a seperate Dataset*/

/*--------------- PART I 
	 Prepare Dataset on Vocatioanl education of Indivudals */

			clear										
			set more off								
			capture log close
			log using "Z:\Projects\<CENSORED_PATH>\ML\Merging\school_creation_process"
			cd "Z:\SUF\On-Site\SC4\SC4_O_12-0-0\Stata14" 	/*-->edit onsite*/

			
			use "SC4_spSchool_O_12-0-0.dta"

	/*drop primary school*/
			drop if ts11204<4
			
/*reverse grades and delete missings*/
			drop if tf11218 <0
			gen grade=6-tf11218
			label var grade "final school grades (GPA)"


	
			
	/*keep relevant variables*/
			keep ID_t splink subspell spell wave tf1112c tf11211 ts11202_g4O ts11204  ts11205 ts11207 ts11209  ts11206_O tf1112c_g1 ts1112m_g1 ts1112y_g1 tf11218 ts11227 ts11228 ts11229 ts11230 grade
			drop if grade==. 
			sort ID_t wave
			duplicates drop ID_t, force
			

 /*Add Controls for class school*/	
 		merge 1:m ID_t using "SC4_CohortProfile_O_12-0-0.dta"		
		
		drop if _merge==2
		drop if _merge==1
		/*keep variables*/
		
		sort ID_t ID_i
		keep  ID_t ID_i grade splink subspell spell wave tf1112c tf11211 ts11202_g4O ts11204  ts11205 ts11207 ts11209  ts11206_O tf1112c_g1 ts1112m_g1 ts1112y_g1 tf11218 ts11227 ts11228 ts11229 ts11230
        
		drop if ID_i==-54
		duplicates drop ID_t ID_i , force
		duplicates list ID_t
		
		/*drop missing values in variables*/
		drop if ID_i==.
		drop if ID_i==-54
		drop if ID_i==-99
		
		
		save  "Z:\Projects\<CENSORED_PATH>\ML\Merging\school_grades", replace

		log close

