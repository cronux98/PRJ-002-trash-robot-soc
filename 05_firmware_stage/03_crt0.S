/* GENERATED-FROM: memory_map.json — DO NOT HAND-EDIT */
/* IP-005 v6 — PicoRV32 RV32IM Boot ROM (crt0.S) */

.section .text._start
.globl _start
_start:
    /* Initialize stack pointer */
    la sp, _stack_top

    /* Clear BSS */
    la t0, _bss_start
    la t1, _bss_end
1:
    bgeu t0, t1, 2f
    sw zero, 0(t0)
    addi t0, t0, 4
    j 1b

2:
    /* Set up trap vector — PicoRV32 uses custom mtvec-like CSR at 0x305 */
    la t0, trap_entry
    .word 0x30529073    /* csrrw x0, mtvec, t0 (PicoRV32-compatible) */

    /* Enable interrupts — PicoRV32 uses custom CSR 0x304 (irq_mask/irq_enable) */
    li t0, -1
    .word 0x30429073    /* PicoRV32: set irq_enable */

    /* Call main */
    call main

    /* Halt if main returns */
halt:
    wfi
    j halt

/* Trap Entry — bare minimum */
.section .text.trap
.globl trap_entry
trap_entry:
    /* Save minimal context */
    addi sp, sp, -64
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw t2, 12(sp)
    sw a0, 16(sp)
    sw a1, 20(sp)
    sw a2, 24(sp)
    sw a3, 28(sp)
    sw a4, 32(sp)
    sw a5, 36(sp)

    /* Read mcause (0x342) and mepc (0x341) — PicoRV32 CSR */
    .word 0x34202573    /* csrr a0, mcause */
    .word 0x341025f3    /* csrr a1, mepc */
    call trap_handler

    /* Restore context */
    lw ra, 0(sp)
    lw t0, 4(sp)
    lw t1, 8(sp)
    lw t2, 12(sp)
    lw a0, 16(sp)
    lw a1, 20(sp)
    lw a2, 24(sp)
    lw a3, 28(sp)
    lw a4, 32(sp)
    lw a5, 36(sp)
    addi sp, sp, 64
    mret

/* Weak default — user code must override */
.weak trap_handler
trap_handler:
    ret

