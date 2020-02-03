.section .data
notfound: .string "-1"
newline: .string "\n"

fstat: .space 144   # Used by get_file_size

.section .text
.global _start
#############################################
#open the search words file and save the length in %r10 and the file in %r13
#############################################
_start:
  # file 1
  # Open the file
  mov $2, %rax
  mov 16(%rsp), %rdi
  mov $0, %rsi
  mov $2, %rdx
  syscall

  mov %rax, %rdi
  
  call get_file_size
  mov %rax, %r10
  call allocate_memory
  mov %rax, %r13
  
  # Read the contents of the file into the buffer
  mov $0, %rax
  mov %r13, %rsi
  mov %r10, %rdx
  syscall
#############################################
#open the search text file and save the length in %r8 and the file in %r15
#############################################
  #file 2
  # Open the file
  mov $2, %rax
  mov 24(%rsp), %rdi
  mov $0, %rsi
  mov $2, %rdx
  syscall

  mov %rax, %rdi
  
  call get_file_size
  mov %rax, %r8
  call allocate_memory
  mov %rax, %r15
  
  # Read the contents of the file into the buffer
  mov $0, %rax
  mov %r15, %rsi
  mov %r8, %rdx
  syscall
#############################################
#find the first search word print it out and then search for it, 
#after that loop back and take next search word.
#then exit when there are no more search words
#############################################
  find_sw_start:
   mov %r13, %r9
  find_sw:
   movb (%r13), %r12b
   mov $1, %rax
   mov $1, %rdi
   mov %r13, %rsi
   mov $1, %rdx
   syscall
   inc %r13
   dec %r10
   cmp $10, %r12b
    jne find_sw
  
   jmp print_place

  run_search_words_done:
   cmp $0, %r10
    jne find_sw_start

  # EXIT
  mov $60, %rax
  mov $0, %rdi
  syscall
#############################################
#searches for the word and if ti finds it it prints out the place in the text,
#if there are no matching words it prints -1
#############################################
  .type print_place, @function
  print_place:
   mov %r15, %rsi      # save the address
   mov %r8, %r11					#%r11 is counter for lenth of search text file, is reset with every new search word
   mov $1, %r14					#counter for number of symbols that has been comparaed
   mov $0, %bh					#flag if start of word matches some text

  # Loop over each letter and compare them  
   mov $0, %rdx					#is for substracting the length of the search word after the whole word is a match
   mov %r9, %r12				#%r12 is the search word so it can be reverted to the begining
  place_loop: 
   cmp $0, %r11					#looks if file to search in is at end
    je end_loop
    
   movb (%r12), %bl				#pulls out 1 byte of each file to compare
   movb (%rsi), %al
   inc %r14						#increase the letter count
   cmp %al, %bl
    je equal_loop
								#goes only further than this if the 2 letters arent identical
   inc %rsi
   mov $0, %rdx
   sub $1, %r11
   cmp $0, %bh					#moves a step back in the search text if the flag is not 0
    jne jmp_back
   jmp_back_done:

   jmp place_loop
    
  equal_loop:
   inc %rdx
   inc %r12
   inc %rsi
   mov $1, %bh					#sets the flag to 1 if it finds 2 identical letters
   sub $1, %r11
   movb (%r12), %bl
   cmp $10, %bl
    je sw_found
	 
   jmp place_loop
    ################
    #search words found
    ################
  sw_found:
   mov %r14, %rax		#%r14 is the next symbols place when the whole word is found
   sub %rdx, %rax		#substract %rdx from the length because %rdx is the length of the word
   jmp print_rax
   print_rax_done:
   jmp run_search_words_done	#then we serach for the next search word
         
  end_loop:
   mov $1, %rax
   mov $1, %rdi
   mov $notfound, %rsi		#prints -1 f the search word is not in text
   mov $4, %rdx
   syscall
   jmp run_search_words_done
###########################
  jmp_back:					#we need to jump 1 symbol back if we find some of the word
   dec %rsi					#but not the whole word, this happens here.
   dec %r14
   inc %r11
   mov $0, %bh
   mov %r9, %r12
   jmp jmp_back_done
##########
.type get_file_size, @function
get_file_size:
  /* Determines the size of a file in bytes. Returns result in %rax.
   * %rax: file descriptor
   */
  push %rbp
  mov %rsp, %rbp

  push %rbx
  push %rcx
  push %rdi
  push %rsi
  push %r12

  # Get fstat 
  mov %rax, %rdi        # file handler
  mov $5, %rax          # syscall fstat
  mov $fstat, %rsi      # reserved space for the stat struct
  syscall
  
  mov $fstat, %rbx
  mov 48(%rbx), %rax    # position of size in the struct

  pop %r12
  pop %rsi
  pop %rdi
  pop %rcx
  pop %rbx

  mov %rbp, %rsp
  pop %rbp
  ret

##########
.type allocate_memory, @function
allocate_memory:
  /* Allocates memory at the end of the heap. Returns pointer in rax.
   * %rax: bytes to allocate
   */
  
  push %rbx
  push %rdi

  mov %rax, %rbx

  # Retrieve current end of heap
  mov $12, %rax           # rax: syscall code
  xor %rdi, %rdi          # rdi: brk
  syscall # sys_brk
  push %rax               # save beginning of new memory

  # Allocate new memory
  add %rbx, %rax
  mov %rax, %rdi          # rdi: brk
  mov $12, %rax           # rax: syscall code
  syscall # sys_brk

  pop %rax
  pop %rdi
  pop %rbx
  ret
##################################### 
 print_rax:
  /* Prints the contents of rax. */
  
  #sub $24, %rax
 
  push  %rbp
  mov   %rsp, %rbp        # function prolog
 
  push  %rax              # saving the registers on the stack
  push  %rcx
  push  %rdx
  push  %rdi
  push  %rsi
  push  %r9
 
  mov   $6, %r9           # we always print the 6 characters "RAX: \n"
  push  $10               # put '\n' on the stack
 
  loop1:
  mov   $0, %rdx
  mov   $10, %rcx
  idiv  %rcx              # idiv alwas divides rdx:rax/operand
                          # result is in rax, remainder in rdx
  add   $48, %rdx         # add 48 to remainder to get corresponding ASCII
  push  %rdx              # save our first ASCII sign on the stack
  inc   %r9               # counter
  cmp   $0, %rax  
  jne   loop1             # loop until rax = 0
 
  push  %rax
  push  %rax
  push  %rax
  push  %rax
  push  %rax
 
  print_loop:
  mov   $1, %rax          # Here we make a syscall. 1 in rax designates a sys_write
  mov   $1, %rdi          # rdx: int file descriptor (1 is stdout)
  mov   %rsp, %rsi        # rsi: char* buffer (rsp points to the current char to write)
  mov   $1, %rdx          # rdx: size_t count (we write one char at a time)
  syscall                 # instruction making the syscall
  add   $8, %rsp          # set stack pointer to next char
  dec   %r9
  jne   print_loop
 
  pop   %r9               # restoring the registers
  pop   %rsi
  pop   %rdi
  pop   %rdx
  pop   %rcx
  pop   %rax
 
  mov   %rbp, %rsp        # function epilog
  pop   %rbp
  jmp print_rax_done 
