@testset "add_agent! (discrete)" begin
    properties = Dict(:x1 => 1)
    space = GraphSpace(complete_digraph(10))
    model = ABM(Agent7, space; properties = properties)
    attributes = (f1 = true, f2 = 1)
    add_agent!(1, model, attributes...)
    attributes = (f2 = 1, f1 = true)
    add_agent!(1, model; attributes...)
    @test model.agents[1].id != model.agents[2].id
    @test model.agents[1].pos == model.agents[2].pos
    @test model.agents[1].f1 == model.agents[2].f1
    @test model.agents[1].f2 == model.agents[2].f2
    @test add_agent_single!(model, attributes...).pos ∈ 1:10
    for id in 4:11
        agent = Agent7(id, 2, attributes...)
        add_agent_single!(agent, model)
    end
    @test !has_empty_positions(model)
    agent = Agent7(12, 5, attributes...)
    add_agent_single!(agent, model)
    @test_throws KeyError model[12]
    add_agent!(agent, model)
    @test model[12].pos ∈ 1:10

    agent = Agent7(13, 5, attributes...)
    @test add_agent!(agent, 3, model).pos == 3

    model = ABM(Agent1, GridSpace((10, 10)))
    agent = Agent1(1, (3, 6))
    @test add_agent!(agent, (7, 8), model).pos == (7, 8)
end

@testset "add_agent! (continuous)" begin
    properties = Dict(:x1 => 1)
    space2d = ContinuousSpace((1, 1), 0.1; periodic = true)
    model = ABM(Agent8, space2d; properties = properties)
    attributes = (f1 = true, f2 = 1)
    add_agent!(model, attributes...)
    attributes = (f2 = 1, f1 = true)
    add_agent!(model; attributes...)
    @test model.agents[1].id != model.agents[2].id
    @test model.agents[1].f1 == model.agents[2].f1
    @test model.agents[1].f2 == model.agents[2].f2
    agent = Agent8(3, (0, 0), false, 6)
    @test 0 <= add_agent!(agent, model).pos[1] <= 1
    agent.id = 4
    @test add_agent!(agent, (0.5, 0.5), model).pos[1] ≈ 0.5 atol = 1e-3
end

@testset "move_agent!" begin
    # GraphSpace
    model = ABM(Agent5, GraphSpace(path_graph(6)))
    agent = add_agent!(model, 5.3)
    init_pos = agent.pos
    # Checking specific indexing
    move_agent!(agent, rand(model.rng, [i for i in 1:6 if i != init_pos]), model)
    new_pos = agent.pos
    @test new_pos != init_pos
    # Checking a random move
    ni = 0
    init_pos = agent.pos
    while agent.pos == init_pos
        move_agent!(agent, model)
    end
    @test ni < Inf

    # GridSpace
    model = ABM(Agent1, GridSpace((5, 5)))
    agent = add_agent!((2, 4), model)
    move_agent!(agent, (1, 3), model)
    @test agent.pos == (1, 3)
    ni = 0
    init_pos = agent.pos
    while agent.pos == init_pos
        move_agent!(agent, model)
    end
    @test ni < Inf

    model = ABM(Agent1, GridSpace((2, 1)))
    agent = add_agent!((1, 1), model)
    move_agent_single!(agent, model)
    @test agent.pos == (2, 1)
    agent2 = add_agent!((1, 1), model)
    move_agent_single!(agent2, model)
    # Agent shouldn't move since the grid is saturated
    @test agent2.pos == (1, 1)

    # ContinuousSpace
    model = ABM(Agent6, ContinuousSpace((1, 1), 0.1))
    agent = add_agent!((0.0, 0.0), model, (0.5, 0.0), 1.0)
    move_agent!(agent, model)
    @test agent.pos == (0.5, 0.0)
end

@testset "kill_agent!" begin
    # No Space
    model = ABM(Agent0)
    add_agent!(model)
    agent = add_agent!(model)
    @test nagents(model) == 2
    kill_agent!(agent, model)
    @test nagents(model) == 1
    add_agent!(model)
    genocide!(model, [1, 3])
    @test nagents(model) == 0
    # GraphSpace
    model = ABM(Agent5, GraphSpace(path_graph(6)))
    add_agent!(model, 5.3)
    add_agent!(model, 2.7)
    @test nagents(model) == 2
    kill_agent!(model.agents[1], model)
    @test nagents(model) == 1
    kill_agent!(2, model)
    @test nagents(model) == 0
    # GridSpace
    model = ABM(Agent1, GridSpace((5, 5)))
    add_agent!((1, 3), model)
    add_agent!((1, 3), model)
    add_agent!((5, 2), model)
    @test nagents(model) == 3
    for id in copy(ids_in_position((1, 3), model))
        kill_agent!(id, model)
    end
    @test nagents(model) == 1
    # ContinuousSpace
    model = ABM(Agent6, ContinuousSpace((1, 1), 0.1))
    add_agent!((0.7, 0.1), model, (15, 20), 5.0)
    add_agent!((0.2, 0.9), model, (8, 35), 1.7)
    @test nagents(model) == 2
    kill_agent!(model[1], model)
    @test nagents(model) == 1
end

@testset "genocide!" begin
    # Testing no space
    model = ABM(Agent0)
    for i in 1:10
        a = Agent0(i)
        add_agent!(a, model)
    end
    genocide!(model)
    @test nagents(model) == 0
    for i in 1:10
        a = Agent0(i)
        add_agent!(a, model)
    end
    genocide!(model, 5)
    @test nagents(model) == 5
    genocide!(model, a -> a.id < 3)
    @test nagents(model) == 3

    model = ABM(Agent3, GridSpace((10, 10)))

    # Testing genocide!(model::ABM)
    for i in 1:20
        agent = Agent3(i, (1, 1), rand(model.rng))
        add_agent_single!(agent, model)
    end
    genocide!(model)
    @test nagents(model) == 0

    # Testing genocide!(model::ABM, n::Int)
    for i in 1:20
        # Explicitly override agents each time we replenish the population,
        # so we always start the genocide with 20 agents.
        agent = Agent3(i, (1, 1), rand(model.rng))
        add_agent_single!(agent, model)
    end
    genocide!(model, 10)
    @test nagents(model) == 10

    # Testing genocide!(model::ABM, f::Function) with an anonymous function
    for i in 1:20
        agent = Agent3(i, (1, 1), rand(model.rng))
        add_agent_single!(agent, model)
    end
    @test nagents(model) == 20
    genocide!(model, a -> a.id > 5)
    @test nagents(model) == 5

    Random.seed!(6465)
    # Testing genocide!(model::ABM, f::Function) when the function is invalid
    # (i.e. does not return a bool)
    for i in 1:20
        agent = Agent3(i, (rand(model.rng, 1:10), rand(model.rng, 1:10)), i * 2)
        add_agent_pos!(agent, model)
    end
    @test_throws TypeError genocide!(model, a -> a.id)
    N = nagents(model)

    # Testing genocide!(model::ABM, f::Function) with a named function
    # No need to replenish population since the last test fails
    function complex_logic(agent::A) where {A<:AbstractAgent}
        if agent.pos[1] <= 5 && agent.weight > 25
            true
        else
            false
        end
    end
    genocide!(model, complex_logic)
    @test nagents(model) < N

    space2d = ContinuousSpace((1, 1), 0.1; periodic = true)
    model = ABM(Agent8, space2d)
    attributes = (f1 = true, f2 = 1)
    for _ in 1:10
        add_agent!(model, attributes...)
    end
    genocide!(model)
    @test nagents(model) == 0
    for _ in 1:10
        add_agent!(model, attributes...)
    end
    genocide!(model, 5)
    @test nagents(model) == 5
    genocide!(model, a -> a.id < 3)
    @test nagents(model) == 3
end

mutable struct Daisy <: AbstractAgent
    id::Int
    pos::Dims{2}
    breed::String
end
mutable struct Land <: AbstractAgent
    id::Int
    pos::Dims{2}
    temperature::Float64
end
@testset "fill space" begin
    space = GridSpace((10, 10))
    model = ABM(Land, space)
    fill_space!(model, 15)
    @test nagents(model) == 100
    for a in allagents(model)
        @test a isa Land
        @test a.temperature == 15
    end

    space = GridSpace((10, 10))
    model = ABM(Union{Daisy,Land}, space; warn = false)
    fill_space!(Daisy, model, "black")
    @test nagents(model) == 100
    for a in values(model.agents)
        @test a isa Daisy
        @test a.breed == "black"
    end

    space = GridSpace((10, 10), periodic = true)
    model = ABM(Union{Daisy,Land}, space; warn = false)
    temperature(pos) = (pos[1] / 10,) # make it Tuple!
    fill_space!(Land, model, temperature)
    @test nagents(model) == 100
    for a in values(model.agents)
        @test a.temperature == a.pos[1] / 10
    end

end

@testset "model step order" begin
    function model_step!(model)
        for a in allagents(model)
            if a.weight > 1.0
                model.count += 1
            end
        end
    end
    function agent_step!(a, model)
        a.weight += 1
    end

    for bool in (true, false)
        model = ABM(Agent2; properties = Dict(:count => 0))
        for i in 1:100
            add_agent!(model, rand(model.rng))
        end
        step!(model, agent_step!, model_step!, 1, bool)
        if bool
            @test model.count == 100
        else
            @test model.count == 0
        end
    end
end

@testset "Higher order groups" begin
    model = ABM(Agent3, GridSpace((10, 10)))
    for i in 1:10
        add_agent!(model, i)
    end

    iter_second_ids = map(x -> (x[1].id, x[2].id), iter_agent_groups(2, model))
    @test size(iter_second_ids) == (10, 10)
    @test iter_second_ids[1] == (1, 1)
    @test iter_second_ids[15] == (5, 2)
    @test iter_second_ids[end] == (10, 10)

    second = collect(map_agent_groups(2, x -> x[1].weight + x[2].weight, model))
    @test size(second) == (10, 10)
    @test second[1] == 2.0
    @test second[15] == 7.0
    @test second[end] == 20.0

    third =
        collect(map_agent_groups(3, x -> x[1].weight + x[2].weight + x[3].weight, model))
    @test size(third) == (10, 10, 10)
    @test third[1] == 3.0
    @test third[15] == 8.0
    @test third[end] == 30.0

    second_filtered =
        collect(map_agent_groups(2, x -> x[1].weight + x[2].weight, model, allunique))
    @test size(second_filtered) == (90,)
    @test second_filtered[1] == 3.0
    @test second_filtered[15] == 9.0
    @test second_filtered[end] == 19.0

    idx_second_filtered = collect(index_mapped_groups(2, model, allunique))
    @test size(idx_second_filtered) == (90,)
    @test idx_second_filtered[1] == (2, 1)
    @test idx_second_filtered[15] == (7, 2)
    @test idx_second_filtered[end] == (9, 10)
end
