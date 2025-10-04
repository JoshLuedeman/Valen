using Valen.Shared;

Console.WriteLine("Valen Orchestrator (walking skeleton)");
if (args.Length == 0)
{
    Console.WriteLine("Usage: valen ingest <path> | ask \"question\"");
    return;
}

switch (args[0])
{
    case "ingest":
        Console.WriteLine($"[stub] Ingesting path: {args.ElementAtOrDefault(1) ?? "(missing)"}");
        break;
    case "ask":
        Console.WriteLine($"[stub] Asking: {string.Join(' ', args.Skip(1))}");
        Console.WriteLine("[stub] Researcher would query local snapshot (VSS) and synthesize an answer.");
        break;
    default:
        Console.WriteLine("Unknown command");
        break;
}
