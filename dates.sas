Data NSW_PublicHolidays;
	Infile Cards Truncover DSD DLM=',';
	Input Date : Date9.
	      Desc : $20.
	       ;
	       
	Format Date Date9.;
	Cards;
01JAN2017, New Year's Day
25DEC2017, Christmas Day
26DEC2017, Boxing Day
26JAN2017, Australia Day
14APR2017, Good Friday
15APR2017, Easter Saturday
16APR2017, Easter Sunday
17APR2017, Easter Monday
25APR2017, ANZAC Day
12JUN2017, Queen's Birthday
07AUG2017, Bank Holiday
02OCT2017, Labour Day
02JAN2017, Additional Day
;
Run;
Data QLD_PublicHolidays;
	Infile Cards Truncover DSD DLM=',';
	Input Date : Date9.
	      Desc : $20.
	       ;
	Format Date Date9.;	      
	Cards;
01JAN2017, New Year's Day
25DEC2017, Christmas Day
26DEC2017, Boxing Day
26JAN2017, Australia Day
14APR2017, Good Friday
15APR2017, Easter Saturday
16APR2017, Easter Sunday
17APR2017, Easter Monday
25APR2017, ANZAC Day
02OCT2017, Queen's Birthday
07AUG2017, Bank Holiday
01MAY2017, Labour Day
14MAY2017, Mother's Day
16AUG2017, Ekka People's Day
03SEP2017, Father's Day
;
Run;

%Macro CreateDateDim(StartDate=, EndDate=);
     Data D_Date(Index=(Date_sk));
           Attrib Date_sk            Length=8.                     Label='PK: Date_sk'
                  Date               Length=8. Format=yymmdd10.    Label='Date'
                  Datetime           Length=8. Format=Datetime22.  Label='Date time'
                  Date_Start_sk      Length=8.
                  Date_End_sk        Length=8.
                  Excel_Date_sk      Length=8.
                  Month_End_Flag     Length=3.
                  Week_End_Flag      Length=3.
                  Num_Day            Length=3.
                  Num_Month          Length=3.
                  Num_Year           Length=3.
                  Num_Quarter        Length=3.
                  NSW_Public_Holiday Length=3.
                  QLD_Public_Holiday Length=3.
                  Fin_Qtr            Length=3.
              %Do i=1 %To 12;
                   PrevDate_&i.m_sk      Length=8. Format=yymmdd10.
                   PrevDate_&i.mStart_sk Length=8. Format=yymmdd10.
                   PrevDate_&i.mEnd_sk   Length=8. Format=yymmdd10.
              %End;
              %Do i=1 %to 12;
                   NextDate_&i.m_sk      Length=8. Format=yymmdd10.
                   NextDate_&i.mStart_sk Length=8. Format=yymmdd10.
                   NextDate_&i.mEnd_sk   Length=8. Format=yymmdd10.
            %End;
                ;
                
         DCL Hash NSWP(Dataset: 'Work.NSW_PublicHolidays', Ordered: 'Y');
         NSWP.DefineKey('Date');
         NSWP.DefineData('Date');
         NSWP.DefineDone();
         
         DCL Hash QLDP(Dataset: 'Work.QLD_PublicHolidays', Ordered: 'Y');
         QLDP.DefineKey('Date');
         QLDP.DefineData('Date');
         QLDP.DefineDone();         
         
         Do Date_sk = "&StartDate."d to "&EndDate"d;
              Date_Start_sk=Intnx('Month', Date_sk, 0, 'begin');
              Date_End_sk=Intnx('Month', Date_sk, 0, 'end');
              Date=Date_sk; 
              Datetime=Date_sk*24*60*60;
              Excel_Date_sk=Date_sk+21916;

              If Date_sk=Date_End_sk Then Month_End_Flag=1;
              Else Month_End_Flag=0;

              /* Create Numerics */
            Num_Day=Day(Date_sk);
            Num_Month=Month(Date_sk);
            Num_Year=Year(Date_sk);
            Num_Quarter=QTR(Date_sk);

              /* Create Texts - long/short*/
            Txt_DOW=Put(Date_sk, DOWName. -L);
            Julian_Date=Put(Date_sk, JulDay. -L);
            Txt_Month_Name=Put(Date_sk, MonName. -L);
            Txt_Week_Date=Put(Date_sk, WeekDate. -L);
            If Strip(Txt_DOW) in ('Saturday' 'Sunday') Then Week_End_Flag=1;
            Else Week_End_Flag=0;

              /* SQL Server Date & Datetime */
              Txt_Date=Put(Date_sk, yymmddd10.);
              Txt_DateTime=Compbl(Put(Date_sk, yymmddd10.)|| ' 00:00:00');

              /* Current Date */
              /* Report Date */

              /* Public Holiday */
             rc=NSWP.Find();
             if rc=0 then NSW_Public_Holiday=1;
             Else NSW_Public_Holiday=0;
             rc=QLDP.Find();
             if rc=0 then QLD_Public_Holiday=1;
             Else QLD_Public_Holiday=0;
              /* Fin Year*/
             Select(Num_Quarter);
             	When (1) Fin_Qtr=3;
             	When (2) Fin_Qtr=4;
             	When (3) Fin_Qtr=1;
             	When (4) Fin_Qtr=2;
             	Otherwise;
             End;

              /* Last Month Dates and Keys - start, end, sameday */
              %Do i=1 %To 12;
                   PrevDate_&i.m_sk=Intnx('Month', Date_sk, -&i., 'same');
                   PrevDate_&i.mStart_sk=Intnx('Month', Date_sk, -&i., 'begin');
                   PrevDate_&i.mEnd_sk=Intnx('Month', Date_sk, -&i., 'end');

                   NextDate_&i.m_sk=Intnx('Month', Date_sk, &i., 'same');
                   NextDate_&i.mStart_sk=Intnx('Month', Date_sk, &i., 'begin');
                   NextDate_&i.mEnd_sk=Intnx('Month', Date_sk, &i., 'end');
              %End;
              /* Month End, Weekend, Quarter End Flags */
            Output;
         End;
     Run;
%Mend;
%CreateDateDim(StartDate=01JAN2017, EndDate=01AUG2017);


Proc SQL Noprint Outobs=1;
	Select Date Into :Report_Date 
	from D_Date 
	where NSW_Public_Holiday=0
      and Week_End_Flag=0
	  and Date < Today()
	Order by Date Desc;
Quit;

%Put Report_Date=&Report_Date.;