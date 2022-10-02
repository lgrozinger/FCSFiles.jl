using FCSFiles
using FileIO
using Test, HTTP

#project_root = isfile("runtests.jl") ? abspath("..") : abspath(".")
project_root = dirname(dirname(@__FILE__))
testdata_dir = joinpath(project_root, "test", "fcsexamples")

if !isdir(testdata_dir)
    run(`git -C $(joinpath(project_root, "test")) clone https://github.com/tlnagy/fcsexamples.git --branch main --depth 1`)
else
    run(`git -C $testdata_dir fetch`)
    # for reproducibility we should use hard reset
    run(`git -C $testdata_dir reset --hard origin/main`)
    run(`git -C $testdata_dir pull`)
end

@testset "FCSFiles test suite" begin
    # test the loading of a large FCS file
    @testset "Loading of large FCS file" begin
        # load the large file
	flowrun = load(joinpath(testdata_dir, "Day 3.fcs"))
        @test length(flowrun) == 50
        @test length(flowrun.params) == 268
    end

    @testset "FlowSample size and length" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)
        @test size(flowrun) == (14, 100000)
        @test length(flowrun) == 14
    end

    @testset "FlowSample keys and haskey" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        expected = [
            "G710-A", "FSC-H", "V545-A", "FSC-A", "G560-A", "Time",
            "SSC-A", "B515-A", "G610-A", "Event #", "R780-A",
            "G780-A", "V450-A", "G660-A",
        ]
        flowrun = load(fn)
        
        for channel in expected
            @test haskey(flowrun, channel)
        end

        @test all(x in keys(flowrun) for x in expected)
    end

    # AxisArray already has tests, here we are just checking that
    # relevant methods get forwarded to their AxisArray implementation
    @testset "Channel access using String" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        for key in keys(flowrun)
            @test flowrun[key] == flowrun.data[key]
        end
    end

    @testset "Multiple channel access using String" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)
        channels = keys(flowrun)
        for (keyA, keyB) in zip(channels[1:end-1], channels[2:end])
            @test flowrun[[keyA, keyB]] == flowrun.data[[keyA, keyB]]
        end
    end

    @testset "Integer sample indexing as second dimension" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        idx = rand(1:size(flowrun, 2))
        @test flowrun.data[:, idx] == flowrun[:, idx]

        @test flowrun.data[:, begin] == flowrun[:, begin]
        
        @test flowrun.data[:, end] == flowrun[:, end]

        rng = range(sort(rand(1:size(flowrun, 2), 2))..., step=1)
        @test flowrun.data[:, rng] == flowrun[:, rng]
    end

    @testset "Mixed indexing with String and Integer" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        idx = rand(1:size(flowrun, 2))
        @test flowrun.data["SSC-A", idx] == flowrun["SSC-A", idx]

        @test flowrun.data[["SSC-A", "FSC-A"], idx] == flowrun[["SSC-A", "FSC-A"], idx]

        rng = range(sort(rand(1:size(flowrun, 2), 2))..., step=1)
        @test flowrun.data["SSC-A", rng] == flowrun["SSC-A", rng]
        
        @test flowrun.data[["SSC-A", "FSC-A"], rng] == flowrun[["SSC-A", "FSC-A"], rng]
    end

    @testset "Logical indexing in second dimension" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        idxs = rand(Bool, size(flowrun, 2))
        @test flowrun.data["SSC-A", idxs] == flowrun["SSC-A", idxs]
    end

    @testset "Convert to Matrix" begin
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        @test Array(flowrun.data) == Array(flowrun)
    end

    @testset "Regression for reading FCS files" begin
        # should catch if changes to the parsing of the file introduce errors
        fn = joinpath(testdata_dir, "BD-FACS-Aria-II.fcs")
        flowrun = load(fn)

        checkpoints = [
            ("SSC-A", 33),
            ("G610-A", 703),
            ("Event #", 382),
            ("FSC-A", 15),
            ("Time", 1),
            ("V450-A", 9938)
        ]

        expected = [585.006f0, 993.2587f0, 3810.0f0, 131008.0f0, 0.0f0, 472.9652f0]

        for (checkpoint, value) in zip(checkpoints, expected)
            @test flowrun[checkpoint[1]][checkpoint[2]] == value
        end
    end
end
