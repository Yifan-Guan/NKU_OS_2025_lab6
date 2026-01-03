#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

static void
fifo_init(struct run_queue *rq)
{
    list_init(&rq->run_list);
    rq->lab6_run_pool = NULL;
    rq->proc_num = 0;
}

static void
fifo_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    list_add_before(&rq->run_list, &proc->run_link);
    if (proc->time_slice <= 0)
    {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num++;
}

static void
fifo_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    list_del_init(&proc->run_link);
    proc->rq = NULL;
    rq->proc_num--;
}

static struct proc_struct *
fifo_pick_next(struct run_queue *rq)
{
    if (list_empty(&rq->run_list))
    {
        return NULL;
    }
    list_entry_t *le = rq->run_list.next;
    return le2proc(le, run_link);
}

static void
fifo_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    /* FCFS is non-preemptive here, so we deliberately avoid setting need_resched. */
    (void)rq;
    (void)proc;
}

struct sched_class fifo_sched_class = {
    .name = "FIFO_scheduler",
    .init = fifo_init,
    .enqueue = fifo_enqueue,
    .dequeue = fifo_dequeue,
    .pick_next = fifo_pick_next,
    .proc_tick = fifo_proc_tick,
};
