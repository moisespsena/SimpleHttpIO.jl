using FactCheck

using SimpleHttpIO

facts("Test io") do
    data = String["For God so loved the world, that he gave his ",
            "only begotten Son, that whosoever ",
            "believeth in him should not perish, but ",
            "have everlasting life.",
            "(John 3:16)"]

    context("writer") do
        io = IOSocket(IOBuffer())

        for d in data
            writeln(io, d)
        end

        seekstart(io.io)

        @fact UTF8String(io.io.data) --> (join(data, CRLF) * "\r\n")
    end

    context("reader") do
        io = IOSocket(IOBuffer())

        for d in data
            writeln(io, d)
        end

        seekstart(io.io)

        context("readbyte") do
            eline = data[1]
            for i in 1:5
                byte = readbyte(io)
                @fact char(byte) --> eline[i]
            end
        end

        seekstart(io.io)

        context("readline") do
            for eline in data
                eline = copy((eline * CRLF).data)
                line = readline(io)
                @fact line --> eline
            end
        end

        seekstart(io.io)

        context("readline_bare") do
            for eline in data
                line = readline_bare(io)
                @fact line --> eline.data
            end
        end

        seekstart(io.io)

        context("readline_str") do
            for eline in data
                eline = eline * CRLF
                line = readline_str(io)
                @fact line --> eline
            end
        end

        seekstart(io.io)

        context("readline_bare_str") do
            for eline in data
                line = readline_bare_str(io)
                @fact line --> eline
            end
        end

        context("Base.eachline") do
            seekstart(io.io)

            context("Base.eachline :s") do
                eachline(io, :s) do itr, line
                    @fact line --> (data[itr.count] * CRLF)
                    if eof(io.io)
                        stop()
                    end
                end
            end

            seekstart(io.io)

            context("Base.eachline :s!") do
                eachline(io, :s!) do itr, line
                    @fact line --> data[itr.count]
                    if eof(io.io)
                        stop()
                    end
                end
            end

            seekstart(io.io)

            context("Base.eachline :b") do
                eachline(io, :b) do itr, line
                    @fact line --> append!(copy(data[itr.count].data), CRLF.data)
                    if eof(io.io)
                        stop()
                    end
                end
            end

            seekstart(io.io)

            context("Base.eachline :b!") do
                eachline(io, :b!) do itr, line
                    @fact line --> data[itr.count].data
                    if eof(io.io)
                        stop()
                    end
                end
            end
        end
    end

end
