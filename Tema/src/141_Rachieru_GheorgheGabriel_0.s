.data
v: .space 4096                   
a: .space 4096                   
nr_op: .long 0                  
op: .long 0                      
nr_fisiere: .long 0              
id_fisier: .long 0               
dimensiune: .long 0              
nr_blocuri: .long 0              
start_blk: .long -1              
end_blk: .long -1                
ok: .long 0                      
found: .long 0                  
formatScanf: .asciz "%d"         
formatPrintf: .asciz "%d: (%d, %d)\n" 
formatPrintfError: .asciz "(0, 0)\n" 
formatPrintfRange: .asciz "(%d, %d)\n" 
formatPrintf1: .asciz "%d: "
fin: .long 0
formatPrintfRange1: .asciz "(%d: %d)\n"
.text
.global main

main:
    push $nr_op
    push $formatScanf
    call scanf
    add $8, %esp

check_nr_op:
    mov nr_op, %eax
    cmp $0, %eax
    je exit_program            

    push $op
    push $formatScanf
    call scanf
    add $8, %esp

    mov op, %eax
    cmp $1, %eax
    je handle_add
    cmp $2, %eax
    je handle_find
    cmp $3, %eax
    je handle_free
    cmp $4, %eax
    je handle_compact

    mov nr_op, %eax
    sub $1, %eax
    mov %eax, nr_op
    jmp check_nr_op

# add
handle_add:
   
    push $nr_fisiere
    push $formatScanf
    call scanf
    add $8, %esp

add_file_loop:
    mov nr_fisiere, %eax
    cmpl $0, %eax
    je end_add

    push $id_fisier
    push $formatScanf
    call scanf
    add $8, %esp

    push $dimensiune
    push $formatScanf
    call scanf
    add $8, %esp

    mov dimensiune, %eax
    add $7, %eax                
    xor %edx, %edx               
    mov $8, %ecx                
    div %ecx
    mov %eax, nr_blocuri

    xor %ebx, %ebx           
    movl $0, found           

add_find_loop:
    mov %ebx, %eax          
    mov nr_blocuri, %ecx
    add %eax, %ecx          
    cmp $1024, %ecx
    jg add_next_file         

    mov $1, %eax
    mov %eax, ok           

    mov %ebx, %eax
    mov %eax, %edx           
add_check_loop:
    mov %edx, %eax
    mov v(,%eax,4), %ecx
    cmp $0, %ecx
    jne add_not_free
    inc %edx
    mov nr_blocuri, %ecx
    add %ebx, %ecx
    cmp %ecx, %edx
    jl add_check_loop

    mov $1, %eax
    mov %eax, found
    jmp add_allocate

add_not_free:
    mov $0, %eax
    mov %eax, ok
    inc %ebx
    jmp add_find_loop

add_allocate:
    mov %ebx, %eax
    mov %eax, start_blk
    mov nr_blocuri, %ecx
    add %ebx, %ecx
    sub $1, %ecx
    mov %ecx, end_blk

    mov start_blk, %eax
    mov %eax, %ebx
    mov end_blk, %ecx
add_allocate_loop:
    cmp %ecx, %ebx
    jg add_allocate_done
    mov id_fisier, %edx
    mov %edx, v(,%ebx,4)
    inc %ebx
    jmp add_allocate_loop

add_allocate_done:

    push end_blk
    push start_blk
    push id_fisier
    push $formatPrintf
    call printf
    add $16, %esp

    mov nr_fisiere, %eax
    sub $1, %eax
    mov %eax, nr_fisiere
    jmp add_file_loop

add_next_file:
    mov $0, %eax
    mov %eax, start_blk
    mov %eax, end_blk
    push end_blk
    push start_blk
    call printf
    add $8, %esp
    jmp add_allocate_done

end_add:
    mov nr_op, %eax
    sub $1, %eax
    mov %eax, nr_op
    jmp check_nr_op

# get
handle_find:
    push $id_fisier
    push $formatScanf
    call scanf
    add $8, %esp

    xor %ebx, %ebx            
    movl $-1, fin             
    xor %eax, %eax            

find_loop:
    cmp $1024, %eax
    je find_done
    mov %eax, %edx
    mov v(,%edx,4), %ecx
    cmp id_fisier, %ecx
    jne continue_find
    mov %eax, fin
    inc %ebx
continue_find:
    inc %eax
    jmp find_loop

find_done:
    cmp $-1, fin              
    je not_found

    mov fin, %eax
    sub %ebx, %eax
    add $1, %eax
    push fin
    push %eax
    push $formatPrintfRange
    call printf
    add $12, %esp
    jmp handle_find_exit

not_found:
    push $0
    push $0
    push $formatPrintfError  
    call printf
    add $12, %esp

handle_find_exit:
    mov nr_op, %eax
    sub $1, %eax
    mov %eax, nr_op
    jmp check_nr_op

#delete

handle_free:
    push $id_fisier
    push $formatScanf
    call scanf
    add $8, %esp

 
    xor %ebx, %ebx          
free_loop:
    cmp $1024, %ebx         
    je end_free              

    mov %ebx, %eax          
    mov v(,%eax,4), %ecx    
    cmp id_fisier, %ecx     
    jne continue_free        

    movl $0, v(,%eax,4)      

continue_free:
    inc %ebx                
    jmp free_loop            

end_free:
    xor %ebx, %ebx          
    xor %esi, %esi          

display_files:
    cmp $1023, %ebx         
    jg finalize_display     

    mov v(,%ebx,4), %eax    
    cmp $0, %eax           
    je skip_to_next          

    mov %eax, %ecx          
    mov %ebx, %esi         
check_sequence:
    inc %ebx                
    mov v(,%ebx,4), %edi    
    cmp %ecx, %edi        
    je check_sequence        

    dec %ebx                
    push %ebx               
    push %esi               
    push %ecx               
    push $formatPrintf
    call printf
    add $16, %esp          

skip_to_next:
    inc %ebx                
    jmp display_files       

finalize_display:
    mov nr_op, %eax
    sub $1, %eax
    mov %eax, nr_op        

    jmp check_nr_op          

# defrag
handle_compact:
    mov $0, %ebx          
    mov $0, %ecx         

compact_loop:
    cmp $1024, %ebx       
    je compact_clear       

    mov %ebx, %eax
    mov v(,%eax,4), %edx  
    cmp $0, %edx
    je continue_compact    

    mov %edx, a(,%ecx,4)  
    inc %ecx              

continue_compact:
    inc %ebx             
    jmp compact_loop      

compact_clear:
    mov $0, %ebx         
clear_v_loop:
    cmp $1024, %ebx
    je compact_update      
    movl $0, v(,%ebx,4)   
    inc %ebx
    jmp clear_v_loop


compact_update:
    mov $0, %ebx          
update_v_loop:
    cmp %ecx, %ebx      
    jge end_compact
    mov %ebx, %eax
    mov a(,%eax,4), %edx  
    mov %edx, v(,%eax,4)  
    inc %ebx
    jmp update_v_loop

end_compact:
    mov $0, %ebx         
    xor %esi, %esi        
    mov $-1, %edi          
    mov $-1, %eax         

display_files_compact:
    cmp $1024, %ebx       
    jge end_display_compact

    mov v(,%ebx,4), %edx  
    cmp $0, %edx          
    je increment_compact

    cmpl $-1, %edi       
    je initialize_start
    cmp %edx, %eax      
    jne finalize_sequence

    mov %ebx, %edi        
    inc %ebx             
    jmp display_files_compact

initialize_start:
    mov %ebx, %esi       
    mov %ebx, %edi        
    mov %edx, %eax        
    jmp display_files_compact

finalize_sequence:

    push %edi            
    push %esi             
    push %eax            
    push $formatPrintf
    call printf
    add $16, %esp        

    mov %ebx, %esi        
    mov $-1, %edi         
    mov %edx, %eax       
    jmp display_files_compact

increment_compact:
    inc %ebx              
    jmp display_files_compact

end_display_compact:
    cmp $-1, %edi         
    je finalize_compact

    push %edi
    push %esi
    push %eax
    push $formatPrintf
    call printf
    add $16, %esp

finalize_compact:
    mov nr_op, %eax
    sub $1, %eax
    mov %eax, nr_op       
    jmp check_nr_op        


# afis vector
display_vector:
    mov $0, %ebx          

vector_loop:
    cmp $1024, %ebx       
    jge end_display_vector

    mov %ebx, %eax        
    mov v(,%eax,4), %ecx  

    push %ecx             
    push %eax             
    push $formatPrintfRange1  
    call printf
    add $12, %esp         

    inc %ebx              
    jmp vector_loop        

end_display_vector:
    ret                    

#iesire
exit_program:
    pushl $0
    call fflush
    popl %eax
   
    mov $1, %eax
    xor %ebx, %ebx
    int $0x80