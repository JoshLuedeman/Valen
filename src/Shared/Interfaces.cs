namespace Valen.Shared;

public record AgentMessage(string Role, string Content);

public interface ILlmClient {
    Task<string> CompleteAsync(string system, string user);
}

public interface IEgressPolicy {
    bool IsAllowed(string toolName, Uri? target, out string reason);
}

public interface IRagClient {
    Task<string[]> SearchAsync(string query, int topK = 5);
    Task IngestPathAsync(string path);
}
