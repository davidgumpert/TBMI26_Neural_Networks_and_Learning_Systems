%% Initialization
%  Initialize the world, Q-table, and hyperparameters

% World and actions
world = 4;
actions = [1 2 3 4];

% Hyperparameters
alpha = 0.5; %learning rate
gamma = 0.9; % discount factor
epsilon = 0.5; % exploration factor
prob_a = [1 1 1 1]; % probability of action 1-4 if randomed

gwinit(world);

s = gwstate()

% Q-table initiate
Q = zeros(s.ysize, s.xsize, length(actions));
Q(:,1,4) = -inf;
Q(:,end,3) = -inf;
Q(1,:,2) = -inf;
Q(end,:,1) = -inf;

goal_counter = 0;
goal_roof = 700;
iterations = 0;

%% Training loop
%  Train the agent using the Q-learning algorithm.
while goal_counter < goal_roof
    [a, oa] = chooseaction(Q, s.pos(1), s.pos(2), actions, prob_a, epsilon);
    new_state = gwaction(a);
    reward = new_state.feedback;
    Q(s.pos(1), s.pos(2), a) = (1 - alpha)*Q(s.pos(1), s.pos(2), a) + alpha*(reward + gamma*max(Q(new_state.pos(1),new_state.pos(2),:)));
    
    if (new_state.isvalid == 1)
        s = new_state;
    end
    
    if (new_state.isterminal == 1)
        Q(new_state.pos(1), new_state.pos(2), :) = 0;
        gwinit(world);
        goal_counter = goal_counter + 1;
    end
    iterations = iterations + 1;
end
epsilon = 0;
P = getpolicy(Q);
V = getvalue(Q);
test_counter = 0;
i = 1;


%% Test loop
%  Test the agent (subjectively) by letting it use the optimal policy
%  to traverse the gridworld. Do not update the Q-table when testing.
%  Also, you should not explore when testing, i.e. epsilon=0; always pick
%  the optimal action.



while test_counter < 100
    [a, oa] = chooseaction(Q, s.pos(1), s.pos(2), actions, prob_a, epsilon);
    new_state = gwaction(a);    
    if (new_state.isvalid == 1)
        s = new_state;
    end
    figure(1)
    gwdraw(i,P)
    if (new_state.isterminal == 1)
        test_counter = test_counter + 1;
        gwinit(world);
    end
    i = i + 1;
end

