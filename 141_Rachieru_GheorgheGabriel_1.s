.data
matrice: .space 4194304   
nr_op: .long 0             
op: .long 0               
id_fisier: .long 0         
dimensiune: .long 0        
nr_blocuri: .long 0        
x1: .long 0               
x2: .long 0                
y: .long 0                 
nr_fisiere: .long 0        
ok: .long 0                
formatScanf: .asciz "%d" 
dataPrintf: .asciz "%d: ((%d, %d), (%d, %d))\n"  
dataPrintf1: .asciz "%d: \n"  
resultPrintf: .asciz "((%d, %d), (%d, %d))\n"   
matrixPrint: .asciz "%d "  
newline: .asciz "\n"       
xinc: .long 0              
yinc: .long 0             
i: .long 0                 
j: .long 0                
nr: .long 0               
temp: .long 0             
index_fisier: .long 0
last_id: .long 0

id_fisiere: .space 4096   
dim_fisiere: .space 4096  
dataPrintf2: .asciz "%d %d %d\n" 
dataPrintf3: .asciz "(%d, %d): %d\n" 
alti: .long 0
.text
.global main

main:
    pushl $nr_op
    pushl $formatScanf
    call scanf
    addl $8, %esp

check_nr_op:
    movl nr_op, %eax
    cmpl $0, %eax
    je exit_program


    pushl $op
    pushl $formatScanf
    call scanf
    addl $8, %esp

    movl op, %eax
    cmpl $1, %eax
    je handle_add
    cmpl $2, %eax
    je handle_get
    cmpl $3, %eax
    je handle_delete
    cmpl $4, %eax
    je handle_defrag

    decl nr_op
    jmp check_nr_op

# add
handle_add:
    pushl $nr_fisiere
    pushl $formatScanf
    call scanf
    addl $8, %esp

add_file_loop:
    movl nr_fisiere, %eax
    cmpl $0, %eax
    je end_add

    pushl $id_fisier
    pushl $formatScanf
    call scanf
    addl $8, %esp

    pushl $dimensiune
    pushl $formatScanf
    call scanf
    addl $8, %esp

    movl dimensiune, %eax
    addl $7, %eax
    xorl %edx, %edx
    movl $8, %ecx
    divl %ecx
    movl %eax, nr_blocuri

   
    xorl %esi, %esi         
find_row_with_space:
    cmpl $1024, %esi        
    je add_error

    xorl %edi, %edi         
    movl $0, ok            

check_row:
    cmpl $1024, %edi       
    je next_row

    movl %esi, %eax         
    imull $1024, %eax
    addl %edi, %eax
    leal matrice(,%eax,4), %ebx

    
    movl nr_blocuri, %ecx   
    movl %edi, %eax         
validate_space:
    cmpl $1024, %eax        
    jge reset_space

    movl %esi, %edx         
    imull $1024, %edx
    addl %eax, %edx
    leal matrice(,%edx,4), %ebx
    movl (%ebx), %edx
    cmpl $0, %edx           
    jne reset_space

    decl %ecx               
    jz space_found          
    incl %eax               
    jmp validate_space

reset_space:
    incl %edi               
    jmp check_row

space_found:
    movl %esi, y          
    movl %edi, x1           
    addl nr_blocuri, %edi   
    decl %edi               
    movl %edi, x2           
    movl $1, ok            
    jmp allocate_block

next_row:
    incl %esi               
    jmp find_row_with_space

add_error:
    movl $0, x1
    movl $0, x2
    movl $0, y
    pushl x2
    pushl y
    pushl x1
    pushl y
    pushl id_fisier
    pushl $dataPrintf
    call printf
    addl $24, %esp
    jmp decrement_files

allocate_block:
    movl %esi, %eax
    imull $1024, %eax
    addl x1, %eax
    leal matrice(,%eax,4), %ebx
    movl id_fisier, %ecx

allocate_loop:
    movl %ecx, (%ebx)     
    addl $4, %ebx
    decl nr_blocuri
    cmpl $0, nr_blocuri
    jg allocate_loop

   
    pushl x2
    pushl y
    pushl x1
    pushl y
    pushl id_fisier
    pushl $dataPrintf
    call printf
    addl $24, %esp

decrement_files:
    decl nr_fisiere
    jmp add_file_loop

end_add:
    decl nr_op
    call display_matrix
    jmp check_nr_op


# GET
handle_get:
    pushl $id_fisier
    pushl $formatScanf
    call scanf
    addl $8, %esp

    xorl %esi, %esi
find_row_get:
    cmpl $1024, %esi
    je not_found

    xorl %edi, %edi
    movl $0, %ebx

find_col_get:
    movl %esi, %eax
    imull $1024, %eax
    addl %edi, %eax
    leal matrice(,%eax,4), %ecx
    movl (%ecx), %edx
    cmpl id_fisier, %edx
    jne next_col_get

    cmpl $0, %ebx
    jne update_end
    movl %edi, x1
    movl $1, %ebx

update_end:
    movl %edi, x2
next_col_get:
    incl %edi
    cmpl $1024, %edi
    jne find_col_get

    cmpl $1, %ebx
    je display_get

    incl %esi
    jmp find_row_get

not_found:
    movl $0, x1
    movl $0, x2
    movl $0, y
    pushl x2
    pushl y
    pushl x1
    pushl y
    pushl $resultPrintf
    call printf
    addl $20, %esp
    decl nr_op
    jmp check_nr_op

display_get:
    movl %esi, %eax
    movl %eax, y
    pushl x2
    pushl y
    pushl x1
    pushl y
    pushl $resultPrintf
    call printf
    addl $20, %esp

    decl nr_op
    jmp check_nr_op

# DELETE
handle_delete:
    pushl $id_fisier
    pushl $formatScanf
    call scanf
    addl $8, %esp

    movl $0, %esi
loop_i_delete:
    cmpl $1024, %esi
    jge display_remaining_files

    movl $0, %edi
loop_j_delete:
    cmpl $1024, %edi
    jge next_i_delete

    movl %esi, %eax
    imull $1024, %eax
    addl %edi, %eax
    leal matrice(,%eax,4), %ebx
    movl (%ebx), %edx
    cmpl id_fisier, %edx
    jne continue_j_delete

    movl $0, (%ebx)

continue_j_delete:
    incl %edi
    jmp loop_j_delete

next_i_delete:
    incl %esi
    jmp loop_i_delete


display_remaining_files:
    movl $0, %esi            
display_files_loop:
    cmpl $1024, %esi         
    je finalize_delete

    movl $0, %edi            
row_loop:
    cmpl $1024, %edi         
    je next_row_display

    movl %esi, %eax
    imull $1024, %eax
    addl %edi, %eax
    leal matrice(,%eax,4), %ebx
    movl (%ebx), %edx
    cmpl $0, %edx           
    je next_col_display

    movl %esi, y             
    movl %edi, x1           

find_end_col:
    movl %edi, %eax
    addl $1, %eax
    cmpl $1024, %eax
    jge finalize_interval

    movl %esi, %ecx
    imull $1024, %ecx
    addl %eax, %ecx
    leal matrice(,%ecx,4), %ebx
    movl (%ebx), %ecx
    cmpl %edx, %ecx
    jne finalize_interval

    movl %eax, x2           
    movl %eax, %edi
    jmp find_end_col

finalize_interval:
    pushl x2
    pushl y
    pushl x1
    pushl y
    pushl %edx              
    pushl $dataPrintf
    call printf
    addl $20, %esp        

    incl %edi
    jmp row_loop

next_col_display:
    incl %edi
    jmp row_loop

next_row_display:
    incl %esi
    jmp display_files_loop

finalize_delete:
    decl nr_op
    jmp check_nr_op


# DEFRAG
handle_defrag:
    # extre fisierele din matrice in vector
  
    call extract_files
       # resetam matriea la 0
    call reset_matrix
    
    # punem fisierele inapoi
    call place_files_from_vector
    
    decl nr_op
   
    jmp check_nr_op

# extract files
extract_files:
    movl $0, i            
    movl $0, j             
    movl $0, index_fisier  
    movl $0, nr_fisiere    

extract_files_loop:
    cmpl $1024, i          
    jge finalize_extract    

    cmpl $1024, j          
    jge next_row_extract    

    imull $1024, i, %eax   
    addl j, %eax            
    leal matrice(,%eax,4), %ebx 
    movl (%ebx), %edx     

    cmpl $0, %edx
    je next_col_extract     

    movl %edx, %eax        
    movl $0, %ecx          
    movl index_fisier, %edi 

check_existing_file:
    cmpl %edi, %ecx        
    jge add_new_file        

    movl id_fisiere(,%ecx,4), %ebx 
    cmpl %eax, %ebx         
    je increment_size       

    incl %ecx             
    jmp check_existing_file

add_new_file:
    movl %eax, id_fisiere(,%edi,4)  
    movl $1, dim_fisiere(,%edi,4)   
    incl index_fisier        
    incl nr_fisiere           
    jmp next_col_extract

increment_size:

    movl dim_fisiere(,%ecx,4), %ebx 
    incl %ebx                       
    movl %ebx, dim_fisiere(,%ecx,4) 
    jmp next_col_extract

next_col_extract:
    incl j                 
    jmp extract_files_loop  

next_row_extract:
    incl i                 
    movl $0, j              
    jmp extract_files_loop  

finalize_extract:

    ret                    

# =resetare matrice
reset_matrix:
    movl $0, i
reset_row_loop:
    cmpl $1024, i
    jge finalize_reset

    movl $0, j
reset_col_loop:
    cmpl $1024, j
    jge next_row_reset

    imull $1024, i, %eax
    addl j, %eax
    leal matrice(,%eax,4), %ebx
    movl $0, (%ebx)       
    incl j
    jmp reset_col_loop

next_row_reset:
    incl i
    jmp reset_row_loop

finalize_reset:
    ret
# afisan fisierele
display_file_vectors:
    pushl %esi               
    pushl %edi               
    pushl %ebx               

    movl nr_fisiere, %esi     
    movl $0, %edi            

display_vector_loop:
    cmpl %esi, %edi           
    jge finalize_display_vectors

    
    movl %edi, %eax
    movl id_fisiere(,%eax,4), %ebx    
    movl dim_fisiere(,%eax,4), %ecx  

  
    pushl %edi
    pushl %ecx
    pushl %ebx
    pushl $dataPrintf2              
    call printf
    addl $16, %esp                   

    incl %edi                        
    jmp display_vector_loop

finalize_display_vectors:
    popl %ebx               
    popl %edi                
    popl %esi               
    ret

# plasare fisiere
place_files_from_vector:
    movl nr_fisiere, %esi       
    cmpl $0, %esi               
    jle end_place_vector1      
    movl $0, alti
    movl $0, %edi               
    movl %edi, temp

place_file_loop_vector1:
    mov nr_fisiere, %esi
    cmpl %esi, temp             
    jge end_place_vector1       

    mov temp, %edi
    movl id_fisiere(,%edi,4), %eax   
    movl dim_fisiere(,%edi,4), %ebx  
    movl %eax, id_fisier            
    movl %ebx, nr_blocuri           

    movl alti, %esi                 

find_row_with_space_vector1:
    cmpl $1024, %esi               
    je add_error_vector1          

    movl $0, %edx                 
    movl nr_blocuri, %ecx          

find_space_in_row_vector1:
    cmpl $1024, %edx               
    jge next_row_vector1          

    movl %esi, %eax
    imull $1024, %eax
    addl %edx, %eax
    leal matrice(,%eax,4), %ebx
    movl (%ebx), %edi              

    cmpl $0, %edi                 
    jne reset_space_vector1        

    decl %ecx                      
    jz space_found_vector1         
    incl %edx                      
    jmp find_space_in_row_vector1

reset_space_vector1:
    incl %edx                      
    jmp find_space_in_row_vector1

space_found_vector1:
   
    movl %esi, y                   
    movl %esi, alti
    movl %edx, x2                 
    subl nr_blocuri, %edx          
    movl %edx, x1                  
    incl x1
    jmp allocate_block_vector1

next_row_vector1:
    incl %esi                      
    jmp find_row_with_space_vector1

add_error_vector1:
    movl $0, x1
    movl $0, x2
    movl $0, y
    pushl x2
    pushl y
    pushl x1
    pushl y
    pushl id_fisier
    pushl $dataPrintf
    call printf
    addl $24, %esp
    jmp increment_file_index_vector1

allocate_block_vector1:
    
    movl y, %eax
    imull $1024, %eax
    addl x1, %eax
    leal matrice(,%eax,4), %ebx
    movl id_fisier, %ecx          

allocate_loop_vector1:
    movl %ecx, (%ebx)            
    addl $4, %ebx                  
    decl nr_blocuri               
    cmpl $0, nr_blocuri            
    jg allocate_loop_vector1       

    pushl x2
    pushl y
    pushl x1
    pushl y
    pushl id_fisier
    pushl $dataPrintf
    call printf
    addl $24, %esp

increment_file_index_vector1:
    incl temp                     
    jmp place_file_loop_vector1

end_place_vector1:
    ret


# afisare matrice
display_matrix:
    xorl %esi, %esi
row_loop2:
    cmpl $1024, %esi
    je end_display
    xorl %edi, %edi
col_loop:
    movl %esi, %eax
    imull $1024, %eax
    addl %edi, %eax
    movl matrice(, %eax,4), %ebx
    pushl %ebx
    pushl $matrixPrint
    call printf
    addl $8, %esp
    incl %edi
    cmpl $1024, %edi
    jne col_loop
    pushl $newline
    call printf
    addl $4, %esp
    incl %esi
    jmp row_loop2
end_display:
    ret
exit_program:
    pushl $0
    call fflush
    popl %eax
    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80