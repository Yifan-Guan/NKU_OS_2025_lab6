#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

static int
proc_sjf_comp_f(void *a, void *b)
{
    struct proc_struct *p = le2proc(a, lab6_run_pool);
    struct proc_struct *q = le2proc(b, lab6_run_pool);
    int32_t diff = (int32_t)p->lab6_priority - (int32_t)q->lab6_priority;
    if (diff < 0)
    {
        return -1;
    }
    else if (diff > 0)
    {
        return 1;
    }
    /* tie-breaker: smaller pid first to keep selection stable */
    if (p->pid < q->pid)
    {
        return -1;
    }
    else if (p->pid > q->pid)
    {
        return 1;
    }
    return 0;
}

static void
sjf_init(struct run_queue *rq)
{
    list_init(&rq->run_list);
    rq->lab6_run_pool = NULL;
    rq->proc_num = 0;
}

static void
sjf_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &proc->lab6_run_pool, proc_sjf_comp_f);
    if (proc->time_slice <= 0)
    {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num++;
}

static void
sjf_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &proc->lab6_run_pool, proc_sjf_comp_f);
    proc->rq = NULL;
    rq->proc_num--;
}

static struct proc_struct *
sjf_pick_next(struct run_queue *rq)
{
    if (rq->lab6_run_pool == NULL)
    {
        return NULL;
    }
    skew_heap_entry_t *she = rq->lab6_run_pool;
    struct proc_struct *p = le2proc(she, lab6_run_pool);
    return p;
}

static void
sjf_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    /* Non-preemptive shortest job first: do not request reschedule on ticks. */
    (void)rq;
    (void)proc;
}

struct sched_class sjf_sched_class = {
    .name = "SJF_scheduler",
    .init = sjf_init,
    .enqueue = sjf_enqueue,
    .dequeue = sjf_dequeue,
    .pick_next = sjf_pick_next,
    .proc_tick = sjf_proc_tick,
};
