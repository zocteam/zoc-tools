# Original block reward for miners was 26 ZOC
start_block_reward = 65000000000000.0
# 262800 is around every year of 456.25 days with a 150 second block interval
reward_interval = 262800.0
def max_money():
    # 26 ZOC = 26 0000 0000 ZOC-Satoshis
    current_reward = 2600000000.0
    previous_reward = current_reward
    total = start_block_reward
    loopi = 0
    while current_reward > 0.999:
        total += reward_interval * current_reward
        current_reward = int ( previous_reward - ( previous_reward/12.0 ) )
        loopi += 1
        print("loop n=", loopi, " , lim(n).ZOC value:", total, ", current reward:", previous_reward, "\n")
        previous_reward = current_reward
    return total
globaltotal = max_money()
print("Total ZOC to ever be created:", globaltotal, "ZOC-Satoshis")