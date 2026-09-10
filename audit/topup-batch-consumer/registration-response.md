# Actual batch result on the public P-TOPUP-2 surface

Independent review a3f2c439 checked e4c92461 and found the value path coherent,
but correctly found no public registration/import consuming it. Its complete
report is retained alongside this response. The report did not establish full
gateway entry correspondence, and neither does this revision.

This revision registers `PTopup2.actual_module_batch_bound` as the current
source result under the unchanged public ID P-TOPUP-2, using the main-result
mechanism already used by the accepted trio. `AllGuarantees` imports the actual
consumer, `Trust` queries it, and UX2 resolves its full source statement and
conditions. The existing trio records remain byte-for-byte equal as JSON
values. The historical abstract/Verity pair remains available and is explicitly
separate from this source result.

The current registered source result consumes the **executed** witness loop,
its produced keys/wei limits, the physical packed cap, rounded target, actual
raw module CALL and the allocations decoded from that same reply. The source
and public theorem are unchanged from the independently inspected e4c92461
candidate; this revision makes them part of the public source surface.

We do not assert that module-selected allocations equal the older greedy
allocator's result. The source allows a module to return zero or fewer
allocations; equating that policy with the historical algorithm is not an
internal invariant that can be derived from Lido. It would add a new premise
and misstate the useful cap promise. The main-result mechanism preserves the
legacy statements while showing the actual source claim and its precise limits.

Still required: project a successful full gateway/router entry onto this value
path with the same source-decoded inputs and physical world, and justify the
specific source errors and announced rollback. These remain unproved
obligations, not accepted external boundaries. This registration is not full
P-TOPUP-2 delivery; all eight campaign guarantees remain OPEN.
