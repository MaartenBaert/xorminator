import matplotlib.pyplot as plt
import numpy as np

num_sims = 16

def ngspice_read(filename):
    with open(filename, 'rb') as f:
        
        readvariables = False
        variables = []
        
        for line in f:
            line = line.decode('utf-8').rstrip()
            
            if readvariables:
                if len(line) > 0 and line[0] == '\t':
                    parts = line.split('\t')
                    if len(parts) > 3:
                        variables.append(parts[2])
                    continue
                readvariables = False
            
            parts = line.split(':', 1)
            if parts[0] == 'Variables':
                readvariables = True
            if parts[0] == 'Binary':
                types = []
                for v in variables:
                    types.append((v, np.float64))
                return np.fromfile(f, dtype=np.dtype(types))
            
        raise Exception('Failed to read spice output!')

results = []
for i in range(num_sims):
    results.append(ngspice_read(f'data/xorminator_source_{i}.raw'))

if len(results) == 1:
    data = results[0]
else:
    types = []
    for v in results[0].dtype.names:
        types.append((v, np.float64, num_sims))
    data = np.zeros(max(len(res) for res in results), dtype=np.dtype(types))
    for (i, res) in enumerate(results):
        for v in res.dtype.names:
            data[v][:len(res), i] = res[v]
            data[v][len(res):, i] = np.nan
alpha = 0.2 + 0.8 * np.exp(-0.1 * (len(results) - 1))

plt.close('all')

if True:
    
    plt.figure('Simulation result', figsize=(10, 5))

    plt.subplot(1, 1, 1)
    for i in range(8):
        p = plt.plot([], [], label=f'osc{i}')
        plt.plot(data['time'] * 1e9, 2 * (7 - i) + data[f'v(osc{i})'], color=p[0].get_color(), alpha=alpha)
    plt.grid(visible=True, which='both', axis='x')
    plt.xlabel('Time (ns)')
    plt.xlim(0, 20)
    plt.yticks([])

    plt.tight_layout()
    plt.show()
