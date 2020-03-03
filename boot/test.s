#NO_APP
	.file	"test.c"
	.text
	.align	2
	.globl	add
	.type	add, @function
add:
	link.w %fp,#-12
	move.l 8(%fp),-4(%fp)
	move.l 12(%fp),-8(%fp)
	move.l -4(%fp),%d0
	add.l -8(%fp),%d0
	move.l %d0,-12(%fp)
	move.l -12(%fp),%d0
	unlk %fp
	rts
	.size	add, .-add
	.align	2
	.globl	main
	.type	main, @function
main:
	link.w %fp,#-8
	moveq #1,%d0
	move.l %d0,-4(%fp)
	moveq #2,%d0
	move.l %d0,-8(%fp)
	move.l -8(%fp),-(%sp)
	move.l -4(%fp),-(%sp)
	jsr add
	addq.l #8,%sp
	unlk %fp
	rts
	.size	main, .-main
	.ident	"GCC: (GNU) 9.2.0"
