-- ARR must always equal MRR x 12.
select mrr.mrr, arr.arr
from {{ ref('mrr') }} as mrr
cross join {{ ref('arr') }} as arr
where arr.arr != mrr.mrr * 12
