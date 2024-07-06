#!/usr/bin/env python
# coding: utf-8

# # Data Analysis for "Making Formulog Fast"
# 
# This Jupyter Notebook analyzes our experimental data.
# It calculates the numbers reported in the paper, and also generates the figures and tables.

# In[1]:


import os
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


# In[2]:


import __main__ as main

if hasattr(main, "__file__"):
    import sys
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} CSV_FILE TIMEOUT")
        exit(1)
    results_file = sys.argv[1]
    timeout = int(sys.argv[2])
else:
    results_file = "results.csv"
    timeout = 1800


# ## Data Wrangling

# In[3]:


data = pd.read_csv(results_file)
data.head()


# In[4]:


def get_time(row):
    if row["mode"].startswith("interpret"):
        val = row["interpret_time"]
    else:
        val = row["execute_time"]
    if pd.isnull(val):
        val = timeout
    return val


# In[5]:


data["time"] = data.apply(get_time, axis=1)


# In[6]:


def get_cpu(row):
    if row["mode"].startswith("interpret"):
        val = row["interpret_cpu"]
    else:
        val = row["execute_cpu"]
    return val


# In[7]:


data["cpu"] = data.apply(get_cpu, axis=1)


# In[8]:


def get_mem(row):
    if row["mode"].startswith("interpret"):
        val = row["interpret_mem"]
    else:
        val = row["execute_mem"]
    return val


# In[9]:


data["mem"] = data.apply(get_mem, axis=1)


# In[10]:


data


# In[11]:


# Rename modes according to what we use in the paper
new_mode_names = {
    "interpret": "interpret",
    "interpret-reorder": "interpret",
    "interpret-unbatched": "interpret-eager",
    "compile": "compile",
    "compile-reorder": "compile",
    "compile-unbatched": "compile-eager",
    "klee": "klee",
    "cbmc": "cbmc",
    "scuba": "scuba",
}

data["mode"] = data["mode"].map(new_mode_names)


# In[12]:


medians = data.groupby(["case_study", "benchmark", "mode"]).agg(
    {
        "smt_time": ["median"],
        "smt_cache_clears": ["median"],
        "time": ["median"],
        "work": ["median"],
        "cpu": ["median"],
        "mem": ["median"],
        "smt_cache_misses": ["median"],
    }
)


# In[13]:


medians.columns = [
    "median_smt_time",
    "median_smt_cache_clears",
    "median_time",
    "median_work",
    "median_cpu",
    "median_mem",
    "median_smt_cache_misses",
]
medians = medians.reset_index()


# In[14]:


medians


# In[15]:


def stats(df, process_row):
    def compute(df):
        res = df.apply(process_row, axis=1).agg(["mean", "min", "median", "max"])
        print(res)

    print("all:")
    compute(df)
    print("\ndminor:")
    compute(df[df["case_study"] == "dminor"])
    print("\nscuba:")
    compute(df[df["case_study"] == "scuba"])
    print("\nsymex:")
    compute(df[df["case_study"] == "symex"])


def speedup(df, mode, baseline):
    """Return the speedup of `mode` relative to `baseline`, calculated as
    `baseline` divided by `mode`"""
    def process_row(row):
        if not pd.isnull(row[mode]):
            return row[baseline] / row[mode]

    return stats(df, process_row)


def widen(df, val):
    return df.pivot(
        index=["case_study", "benchmark"], columns="mode", values=val
    ).reset_index()


# In[16]:


times = widen(medians, "median_time")
smt_times = widen(medians, "median_smt_time")
work = widen(medians, "median_work")
cpu = widen(medians, "median_cpu")
mem = widen(medians, "median_mem")
smt_cache_misses = widen(medians, "median_smt_cache_misses")


# In[17]:


def smt_heavy(df):
    return df[(df["case_study"] != "scuba")]


# ## Overall Performance
# 
# The overall performance improvement relative to the baseline interpreter, using compilation and eager evaluation (as appropriate):

# In[18]:


def print_nice(msg):
    print()
    print("################################################################################")
    print(msg)
    print()


# In[19]:


def best_compile_vs_interpret(row):
    if row["case_study"] != "scuba":
        return row["interpret"] / row["compile-eager"]
    return row["interpret"] / row["compile"]

print_nice("Speedup of best compile mode over interpret (used in Table 1)")
stats(times, best_compile_vs_interpret)


# In[20]:


print_nice("Speedup of compile over interpret on SMT-heavy benchmarks (used in Table 1)")
speedup(smt_heavy(times), "compile", baseline="interpret")


# In[21]:


def compile_or_interpret_eager_vs_interpret(row):
    if row["case_study"] != "scuba":
        return row["interpret"] / row["interpret-eager"]
    return row["interpret"] / row["compile"]


print_nice("Speedup of compile (SMT-light benchmarks) or interpret-eager (SMT-heavy benchmarks) over interpret (used in Table 1)")
stats(times, compile_or_interpret_eager_vs_interpret)


# In[22]:


print_nice("Speedup of interpret-eager over interpret on SMT-heavy benchmarks (used in Table 1)")
speedup(smt_heavy(times), "interpret-eager", baseline="interpret")


# ## Section 3.3 (Semi-Naive Compiler Experiments)

# In[23]:


print_nice("Speedup of compile over interpret (used in Table 1)")
speedup(times, "compile", baseline="interpret")


# In[24]:


print_nice("Memory usage of interpret over compile")
speedup(mem, "compile", baseline="interpret")


# In[25]:


base_compiler_data = data[(data["mode"] == "interpret") | (data["mode"] == "compile")]


# In[26]:


os.makedirs("figures", exist_ok=True)


# In[27]:


# From https://jwalton.info/Embed-Publication-Matplotlib-Latex/
def set_size(width, fraction=1, subplots=(1, 1)):
    """Set figure dimensions to avoid scaling in LaTeX.

    Parameters
    ----------
    width: float or string
            Document width in points, or string of predined document type
    fraction: float, optional
            Fraction of the width which you wish the figure to occupy
    subplots: array-like, optional
            The number of rows and columns of subplots.
    Returns
    -------
    fig_dim: tuple
            Dimensions of figure in inches
    """
    if width == "thesis":
        width_pt = 426.79135
    elif width == "beamer":
        width_pt = 307.28987
    else:
        width_pt = width

    # Width of figure (in pts)
    fig_width_pt = width_pt * fraction
    # Convert from pt to inches
    inches_per_pt = 1 / 72.27

    # Golden ratio to set aesthetic figure height
    # https://disq.us/p/2940ij3
    golden_ratio = (5**0.5 - 1) / 2

    # Figure width in inches
    fig_width_in = fig_width_pt * inches_per_pt
    # Figure height in inches
    fig_height_in = fig_width_in * golden_ratio * (subplots[0] / subplots[1])

    return (fig_width_in, fig_height_in)


width = 395.8225


# In[28]:


# Figure 4

plt.clf()
sns.set_theme()

tex_fonts = {
    # Use LaTeX to write all text
    # "text.usetex": True,
    "font.family": "sans-serif",
    # Use 9pt font in plots
    "axes.labelsize": 9,
    "font.size": 9,
    # Make the legend/label fonts a little smaller
    "legend.fontsize": 8,
    "xtick.labelsize": 8,
    "ytick.labelsize": 8,
    "text.latex.preamble": r"\usepackage[cm]{sfmath}",
}

plt.rcParams.update(tex_fonts)

fig, (ax1, ax2) = plt.subplots(1, 2)
modes = ["interpret", "compile"]
case_studies = ["dminor", "scuba", "symex"]
sns.stripplot(
    data=base_compiler_data,
    y="case_study",
    hue="mode",
    x="time",
    jitter=True,
    dodge=True,
    hue_order=modes,
    order=case_studies,
    legend=None,
    alpha=0.3,
    ax=ax1,
    palette="viridis",
)
ax1.set(ylabel="Case study", xlabel="Runtime (s)")

sns.stripplot(
    data=base_compiler_data,
    y="case_study",
    hue="mode",
    x="mem",
    jitter=True,
    dodge=True,
    hue_order=modes,
    order=case_studies,
    legend=None,
    alpha=0.3,
    ax=ax2,
    palette="viridis",
)
ax2.tick_params(axis="y", which="both", left=False, labelleft=False)
ax2.set(ylabel=None, xlabel="Memory usage (GB)")

leg = fig.legend(modes)
for lh in leg.legend_handles:
    lh.set_alpha(1)
(inch_width, _) = set_size(width)
fig.set_size_inches(inch_width, 2.5)
plt.tight_layout()
plt.savefig(os.path.join("figures", "fig4.pdf"), bbox_inches="tight", dpi=100)


# ## Section 5.3 (Eager Evaluation Experiments)

# In[29]:


print_nice("Speedup of interpret-eager over interpret on SMT-heavy benchmarks (used in Table 1)")
speedup(smt_heavy(times), "interpret-eager", baseline="interpret")


# In[30]:


print_nice("Speedup of interpret-eager over compile on SMT-heavy benchmarks")
speedup(smt_heavy(times), "interpret-eager", baseline="compile")


# In[31]:


print_nice("Speedup of compile-eager over interpret-eager on SMT-heavy benchmarks")
speedup(smt_heavy(times), "compile-eager", baseline="interpret-eager")


# In[32]:


print_nice("Speedup of compile-eager vs compile on SMT-heavy benchmarks")
speedup(smt_heavy(times), "compile-eager", baseline="compile")


# In[33]:


print_nice("Memory usage of interpret-eager over interpret on SMT-heavy benchmarks")
speedup(smt_heavy(mem), "interpret", baseline="interpret-eager")


# In[34]:


print_nice("Memory usage of compile-eager over compile on SMT-heavy benchmarks")
speedup(smt_heavy(mem), "compile", baseline="compile-eager")


# In[35]:


print_nice("CPU usage of interpret-eager over interpret on SMT-heavy benchmarks")
speedup(smt_heavy(cpu), "interpret", baseline="interpret-eager")


# In[36]:


print_nice("CPU usage of compile-eager over compile on SMT-heavy benchmarks")
speedup(smt_heavy(cpu), "compile", baseline="compile-eager")


# In[37]:


print_nice("Extra work done by interpret-eager over interpret on SMT-heavy benchmarks")
speedup(smt_heavy(work), "interpret", baseline="interpret-eager")


# In[38]:


print_nice("Extra work done by compile over compile-eager on SMT-heavy benchmarks")
speedup(smt_heavy(work), "compile-eager", baseline="compile")


# In[39]:


print_nice("Extra SMT cache misses by compile over interpret-eager on SMT-heavy benchmarks")
speedup(smt_heavy(smt_cache_misses), "interpret-eager", baseline="compile")


# In[40]:


print_nice("Extra SMT caches by compile over compile-eager on SMT-heavy benchmarks")
speedup(smt_heavy(smt_cache_misses), "compile-eager", baseline="compile")


# In[41]:


print_nice("SMT solving time speedup of interpret-eager over compile on SMT-heavy benchmarks")
speedup(smt_heavy(smt_times), "interpret-eager", baseline="compile")


# In[42]:


print_nice("SMT solving time speedup of compile-eager over compile on SMT-heavy benchmarks")
speedup(smt_heavy(smt_times), "compile-eager", baseline="compile")


# In[43]:


eager_eval_data = data[data["case_study"] != "scuba"]


# In[44]:


# Figure 6

plt.clf()
sns.set_theme()

tex_fonts = {
    # Use LaTeX to write all text
    # "text.usetex": True,
    "font.family": "sans-serif",
    # Use 9pt font in plots
    "axes.labelsize": 9,
    "font.size": 9,
    # Make the legend/label fonts a little smaller
    "legend.fontsize": 8,
    "xtick.labelsize": 8,
    "ytick.labelsize": 8,
    "text.latex.preamble": r"\usepackage[cm]{sfmath}",
}

plt.rcParams.update(tex_fonts)

fig, (ax1, ax2) = plt.subplots(1, 2)
modes = ["interpret", "compile", "interpret-eager", "compile-eager"]
case_studies = ["dminor", "symex"]
sns.stripplot(
    data=eager_eval_data,
    y="case_study",
    hue="mode",
    x="time",
    jitter=True,
    dodge=True,
    hue_order=modes,
    order=case_studies,
    legend=None,
    alpha=0.3,
    ax=ax1,
    palette="viridis",
)
ax1.set(ylabel="Case study", xlabel="Runtime (s)")

sns.stripplot(
    data=eager_eval_data,
    y="case_study",
    hue="mode",
    x="smt_time",
    jitter=True,
    dodge=True,
    hue_order=modes,
    order=case_studies,
    legend=None,
    alpha=0.3,
    ax=ax2,
    palette="viridis",
)
ax2.tick_params(axis="y", which="both", left=False, labelleft=False)
ax2.set(ylabel=None, xlabel="SMT solving time (s)")

leg = fig.legend(modes, loc="upper center", bbox_to_anchor=(0.5, 1.05), ncol=4)
for lh in leg.legend_handles:
    lh.set_alpha(1)
fig.set_size_inches(inch_width, 2.5)
plt.tight_layout()
plt.savefig(os.path.join("figures", "fig6.pdf"), bbox_inches="tight", dpi=100)


# ## Section 6.1 (Comparison to Reference Implementations)

# In[45]:


print_nice("Speedup of scuba (reference implementation) over compile")
speedup(times[times["benchmark"] != "luindex"], "scuba", baseline="compile")


# In[46]:


print_nice("Speedup of scuba (reference implementation) over interpret")
speedup(times[times["benchmark"] != "luindex"], "scuba", baseline="interpret")


# In[47]:


print_nice("Speedup of compile-eager over klee")
speedup(times, "compile-eager", baseline="klee")


# In[48]:


print_nice("Speedup of interpret over klee")
speedup(times, "interpret", baseline="klee")


# In[49]:


print_nice("Speedup of cbmc over compile-eager")
speedup(times, "cbmc", baseline="compile-eager")


# In[50]:


# Hard-code the Dminor times reported in the original Formulog paper
def dminor(row):
    match row["benchmark"]:
        case "all-1":
            return min(1.5, timeout)
        case "all-10":
            return min(68, timeout)
        case "all-100":
            return timeout


times["dminor"] = times.apply(dminor, axis=1)


# In[51]:


# Table 2


def make_table_row(row, acc):
    def time(mode, is_ref=False):
        if mode == "scuba" and row["benchmark"] == "luindex":
            return "error"
        if pd.isnull(row[mode]):
            return "-"
        if row[mode] == timeout:
            return "TO"
        else:
            t = f"{row[mode]:0.2f}"
            em = t == best_flg and not is_ref
            bf = t == best
            if em:
                t = "{\\em %s}" % t
            if bf:
                t = "{\\bf %s}" % t
            return t

    if row["case_study"] == "dminor":
        ref = "dminor"
    elif row["case_study"] == "scuba":
        ref = "scuba"
    else:
        ref = "klee"
    ref_time = row[ref]
    if row["benchmark"] == "luindex":
        ref_time = 1000000000

    times = [
        row["interpret"],
        row["interpret-eager"],
        row["compile"],
        row["compile-eager"],
    ]
    best_flg = min(t for t in times if not pd.isnull(t))
    best = min(best_flg, ref_time)
    best_flg = f"{best_flg:0.2f}"
    best = f"{best:0.2f}"

    s = []
    if row["case_study"] != "scuba":
        s.append(r"\rowcolor{Gray} ")
    s.append(f"{row['case_study']} & {row['benchmark']}")
    s.extend([" & ", time("interpret")])
    s.extend([" & ", time("interpret-eager")])
    s.extend([" && ", time("compile")])
    s.extend([" & ", time("compile-eager")])
    s.extend([" && ", time(ref, True), r"\\"])
    acc.append("".join(s))


s = []
s.append(r"\documentclass{article}")
s.append(r"\usepackage{colortbl}")
s.append(r"\usepackage{multirow}")
s.append(r"\usepackage{color}")
s.append(r"\usepackage{booktabs}")
s.append(r"\definecolor{Gray}{gray}{0.9}")
s.append(r"\begin{document}")
s.append(r"\begin{tabular}{ll rr rrr rr}")
s.append(r"\toprule")
s.append(
    r"& & \multicolumn{2}{c}{Formulog interp. (s)} && \multicolumn{2}{c}{Formulog compile (s)} && Reference \\"
)
s.append(r"\cline{3-4} \cline{6-7}")
s.append(
    r"Case study & Benchmark & semi-naive & eager && semi-naive & eager && impl. (s) \\"
)
s.append(r"\midrule")
times.apply(lambda row: make_table_row(row, s), axis=1)
s.append(r"\bottomrule")
s.append(r"\end{tabular}")
s.append(r"\end{document}")
with open(os.path.join("figures", "tab2.tex"), "w") as f:
    f.write("\n".join(s))


# In[ ]:





# In[ ]:




