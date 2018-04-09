INCLUDE Irvine32.inc
.data

filepath byte "C:\Users\Islam\Desktop\University\Assembly\Project\final project\Test.txt",0
savefilepath byte "C:\Users\Islam\Desktop\University\Assembly\Project\final project\output.txt",0
filehandle byte ?
datarange =1000
filedata byte datarange dup(?)


equal byte '='
sampleno dword ? ;T  
sequencelength dword ? ;N
pattern dword ?  ;L
mutations dword ? ;M

value dword 0 
multiplier dword 10
const byte 10 ;for parsing the numbers from string to int

dnasize dword ?	;Size of the DNA Sequence. 
dna byte 1000 dup(?)
dnacolors byte 1000 dup(0)
consoleHandle Handle ?


counter1 dword  0 
counter2 dword  0 
counter3 dword  0
mutationscount dword 0 
startindex dword 0 
searchindex dword 0 
blockindex dword 0 
blockmutations dword 10000 ;Contains the least number of mutations in the block.
allmutations dword 0 ;Contains the all mutations of the current search. 
prevallmutations dword 100000 ;Contains the least number of all mutations.
output dword 100 dup(?) ; Contains the indecies of the current search.
prevoutput dword 100 dup(?) ; Contains the least indecies among the program.
nomatch dword 0 
OutputString byte 10000 dup (?) 
TEN Dword 10
numbersize Dword ?
outputstringsize Dword 0
byteswritten dword ? 
Addon Dword 0

.code

main PROC


	call Read_from_file 
	call Parse_Variables
	call Get_DNA
	call Find_Minimum_Sequence
	call Close_File
	call Display

 



;mov ebx , 0 
;mov ecx , sampleno
;
;l10: 
;mov eax , prevoutput[ebx]
;add ebx ,4 
;call writeint
;
;loop l10 
;
;call crlf 


EXIT
main ENDP	


;-----------------------------------------------------------------------
;Open the file for reading and read it in a string.
;Recieves: Nothing.
;Returns : The file contents in string filedata .
;-----------------------------------------------------------------------
Read_from_file proc 

	; Open file for reading. 

	mov edx , offset filepath
	call openinputfile 
	cmp eax , INVALID_HANDLE_VALUE
	je error
	mov filehandle , al 


	; Read from file.
 
	mov edx , offset filedata
	mov ecx , datarange
	call readfromfile 
	cmp eax , 0 
	je error 
	jmp skip

	; Invalid file path.
	error:
	CALL WriteWindowsMsg

	skip: 

ret 
Read_from_file ENDP


;-----------------------------------------------------------------------
;Parse variables from filedata imported from the file into variables.
;Recieves: filedata string to wrok on it.
;Returns: Parsed variables in sampleno, sequencelength, pattern and mutattions.
;-----------------------------------------------------------------------
Parse_Variables proc 

	; Preparing variables and counters.

	mov al , ','
	mov ecx ,4 
	mov bl , 1  ;choice 
	mov bh , 1	;mult 

	mov edx , 0
	mov edi , offset filedata
	mov esi , offset filedata

	;Search for ',' and move backward pushing the numbers till finding '='.

	l1:
	mov al , ','
	cld 
	push ecx 
	mov edi , esi
	mov ecx , 35
	repne scasb  
	jz extract 
	jmp skip


	extract:
	mov esi , edi 
	dec edi 

	decrease:
	dec edi 
	mov dl, equal 
	cmp [edi], dl
	je skip 

	cmp bh ,1 
	je first
	mov edx , 0 
	mov al, [edi]
	sub al , 48
	mul multiplier 
	add value , eax
	mov eax , multiplier 
	mul const
	mov word ptr multiplier ,ax 
	inc bh 
	jmp decrease 

	first:
	mov eax , 0
	mov al, [edi]
	sub al , 48
	add value , eax 
	inc bh 
	jmp decrease

	skip:

	;Choose the suitable variable to initialize.

	cmp bl , 1 
	je init_T
	cmp bl ,2 
	je init_N
	cmp bl ,3 
	je init_L
	cmp bl ,4 
	je init_M



	init_T:
	mov eax , value 
	mov sampleno , eax 
	jmp skip2 

	init_N: 
	mov eax, value 
	mov sequencelength ,eax 
	jmp skip2 


	init_L:
	mov eax , value 
	mov pattern ,eax 
	jmp skip2  


	init_M:
	mov eax , value 
	mov mutations ,eax 

	skip2:
	mov value , 0 
	mov bh , 1 
	inc bl 
	pop ecx 
	dec ecx 
	cmp ecx , 0 
	je breakloop 
	jmp l1


	breakloop:
ret 
Parse_Variables ENDP

;-----------------------------------------------------------------------
;Gets the DNA full sequence size and put the full sequence in DNA string. 
;Recieves: Sampleno
;Returns: Dnasize which contains the size of the dna and DNA which contains the DNA full sequence itself.
;------------------------------------------------------------------------
 Get_DNA proc 

	;getting dna sequence size 
	mov edx , 0 
	mov eax ,0
	mov eax , sampleno
	mul sequencelength
	mov dnasize , eax 


	;putting the dna in dna string
	add esi , 5 
	mov ebx , 0 
	mov ecx , dnasize

	l2: 
	mov al , [esi] 
	mov dna[ebx] ,al 
	inc ebx 
	inc esi
	loop l2

ret 
Get_DNA ENDP

;-----------------------------------------------------------------------
;Finds the DNA sub sequence with minmum mutations.  
;Recieves: Dna string and work variables (sequencelength, pattern, sampleno, mutations).
;Returns: Array contains the indecies of the best sequence found in prevoutput.
;------------------------------------------------------------------------
 Find_Minimum_Sequence proc 

	; Initilaizing loops counters. 
	mov ecx , 0 
	mov ecx , sequencelength
	mov counter1,ecx
	mov ecx , pattern
	sub counter1 , ecx 
	inc counter1
	mov ecx, sampleno
	mov counter2,ecx
	dec  counter2 
	mov ecx , pattern 
	mov counter3 ,ecx 
	mov eax , 0 

	; Getting the sequence part
	mov ecx , counter1 
	; The first loop which loops on the fixed block N-L+1 times.
	Basic_Loop:

	mov edx , 0 
	push ecx 
	mov ecx , counter2
	mov eax , startindex
	mov output[edx], eax
	add edx ,4 
	; The second loop which loops on the other blocks T-1 times. 
		Blocks_Loop:

		push ecx
		mov ecx , counter1  
		mov eax , sequencelength
		add blockindex , eax
		mov eax , blockindex
		mov searchindex ,eax 

			; The third loop which loops on a specified block N-L+1 times.
			Block_Search:
			mov mutationscount , 0
			push ecx 
			mov ecx , counter3 
			mov ebx , 0 

				; The fourth loop which make the main comparison.
				Comparison_Loop:
				mov esi , startindex
				add esi , ebx 
				mov edi , searchindex 
				add edi ,ebx 
				inc ebx 
				mov al , dna[edi]
				mov ah , dna[esi]
				cmp dna[esi] , al
				jne mut
				jmp complete

				mut:
				mov eax , 0 
				inc mutationscount
				mov eax , mutationscount 

				cmp mutations, eax 
				jb exceed

				complete:
				loop Comparison_Loop 
				; Comparison_Loop end.
			mov eax , mutationscount
			cmp eax , blockmutations
			jae exceed1

			mov blockmutations , eax 
			mov eax , searchindex


			mov output[edx],eax
 
			jmp exceed1


			exceed:
			inc nomatch
			exceed1:
			inc searchindex
			pop ecx 
			dec ecx 
			cmp ecx , 0 
			jne Block_Search
			; Block_Search end.

		mov eax , 0 
		add edx , 4
		mov eax , nomatch
		cmp eax ,counter1 
		jne here
		pop ecx 
		jmp Start_beggining 
		here:
		mov nomatch , 0
		mov eax , 0 
		mov eax , blockmutations
		add allmutations ,eax 

		mov blockmutations , 10000
		pop ecx 
		dec ecx 
		cmp ecx, 0 
		jne Blocks_Loop    
		; Blocks_Loop end.
 
	 mov eax , allmutations 
	 cmp eax, prevallmutations 

	 jAe Start_beggining
	 mov ecx , sampleno 
	 mov edx , 0 
	 fill:
	 mov eax , output[edx]
	 mov prevoutput[edx],eax 
	 add edx , 4 
	 loop fill 
 
	 mov eax , allmutations
	 mov prevallmutations ,eax
 
	 Start_beggining:
 
	inc startindex
	pop ecx 
	dec ecx 
	mov eax , nomatch
	mov nomatch , 0
	cmp eax , counter1
	mov blockindex , 0
	 mov allmutations , 0
	cmp ecx , 0 
	jne Basic_Loop 
	 ; Basic_Loop end 

 ret 
 Find_Minimum_Sequence ENDP

;-----------------------------------------------------------------------
;Closes the test case file. 
;Recieves: filehandle
;Returns: Nothing. 
;-----------------------------------------------------------------------
 Close_File proc 

	movzx eax , filehandle
	call closefile 
  ret 
  Close_file ENDP
 

;-----------------------------------------------------------------------
;Save the final output stored in prevoutput in a file and display all mutations on the console while highlighting the selected ones. 
;Recieves: filehandle for the output file.
;Returns: File contains the Output. 
;-----------------------------------------------------------------------
 Display proc 

	call Highlight
	pushad
	INVOKE GetStdHandle , STD_OUTPUT_HANDLE
	mov consoleHandle , eax
	popad
	mov ecx , dnasize
	mov ebx ,0
	mov edx , 0


	; Dispalying the colors according to the highlighting procedure 
	; 0 for white , 1 for red and 2 for green
DisplayDNA:
	cmp dnacolors[ebx] , 0
	je writeWhite
	cmp dnacolors[ebx] , 1
	je writeRed
	cmp dnacolors[ebx] , 2
	je writeGreen

writeWhite:
	pushad
	INVOKE SetConsoleTextAttribute , consoleHandle , white
	popad
	jmp done
writeRed:
	pushad
	INVOKE SetConsoleTextAttribute , consoleHandle , red
	popad
	jmp done
writeGreen:
	pushad
	INVOKE SetConsoleTextAttribute , consoleHandle , green
	popad
done:
	cmp edx , sequencelength
	jne skip
	call crlf
	mov edx , 0
skip:
	mov al , dna[ebx]
	call writechar
	inc ebx
	inc edx
Loop DisplayDNA

	
	mov ecx , sampleno
	mov esi , offset prevoutput
	mov edi , offset OutputString

		GetNumber :
		push ecx
		mov ebx , [esi]
		sub ebx , addon
		inc ebx 
		mov eax , sequencelength
		add addon , eax 
		mov numbersize , 0
			Getdigit:
				mov edx , 0 
				mov eax , ebx
				div TEN
				push edx 
				inc numbersize 
				mov ebx , eax
				cmp eax , 0
				jne Getdigit
			mov ecx , numbersize 
			WriteByte:
			pop edx 
			add dl,'0'
			mov [edi],dl
			inc edi
			inc outputstringsize
			loop WriteByte
			cmp ecx , 1
			je cont11
			mov dl , ','
			mov [edi],dl
			inc edi 
			inc outputstringsize
			mov dl , ' '
			mov [edi],dl
			inc outputstringsize
			cont11:
			add esi , 4  
		pop ecx
		loop Getnumber 

	
	call crlf
	; writing to the file 

	call Write_To_File
 ret 
 Display ENDP


;-----------------------------------------------------------------------
;Assign the colors according to the mutations
;Recieves: prevoutput which uses it for highlighting the found motif.
;Returns: Dnacolors which is responsible for coloring motif and different mutations. 
;-----------------------------------------------------------------------
Highlight proc 

	mov eax , prevoutput[0]
	mov startindex , eax
	mov ebx , 0
	mov ecx , pattern
	InitOriginalMotif:
		mov esi , startindex
		add esi , ebx
		mov dnacolors[esi] , 2
		inc ebx
	loop InitOriginalMotif

	mov ecx , sampleno
	dec ecx
	mov ebx , 4
	IterateOnMotifs:
	mov eax , prevoutput[0]
	mov startindex , eax
	mov edx , 0
	mov eax , prevoutput[ebx]
	add ebx , 4
	mov searchindex , eax
		push ecx
		mov ecx , pattern
		mov edx , 0
		CompareMotifs:
			mov esi , searchindex
			add esi , edx
			mov al , dna[esi]
			mov edi , startindex
			add edi , edx
			mov ah , dna[edi]
			cmp ah , al
			JE ColorGreen
			mov dnacolors[esi] , 1 ; 1 =red
			jmp done
			ColorGreen:
			mov dnacolors[esi] , 2 ; 2 =green , 0 =white by default 
			done:
			inc edx
		loop CompareMotifs
		pop ecx
	loop IterateOnMotifs
 ret 
 Highlight ENDP



;-----------------------------------------------------------------------
;Write the final output to the file.
;Recieves: savefilepath.
;Returns: File contains the answer. 
;-----------------------------------------------------------------------
 Write_To_File PROC
	mov edx , offset saveFilepath
	INVOKE CreateFile , edx , GENERIC_ALL , DO_NOT_SHARE , NULL , CREATE_ALWAYS , FILE_ATTRIBUTE_NORMAL ,0
	mov edx , offset OutputString
	mov ecx , outputstringsize
	INVOKE WriteFile , eax , edx , ecx , ADDR bytesWritten , 0
 ret
 Write_To_File ENDP
 end main







