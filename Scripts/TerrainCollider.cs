
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class TerrainCollider : UdonSharpBehaviour {
    VRCPlayerApi localPlayer;

    void Start() {
        localPlayer = Networking.LocalPlayer;
    }
    
    float Terrain(Vector2 uv) {
        return (Mathf.Cos(uv.x * 0.03f) + Mathf.Cos(uv.y * 0.03f)) * 10.0f;
    }

    Vector2 DeltaTerrain(Vector2 uv) {
        return new Vector2(Mathf.Sin(uv.x * 0.03f), Mathf.Sin(uv.y * 0.03f) * 10.0f);
    }
    
    private float height;
    private Vector3 playerPosition;
    private Vector2 uv;
    void PostLateUpdate() {
        height = Terrain(uv);
        playerPosition = localPlayer.GetPosition();
        uv = new Vector2(playerPosition.x, playerPosition.z);
        
        transform.position = new Vector3(
            playerPosition.x,
            height,
            playerPosition.z
        );
    }
}
