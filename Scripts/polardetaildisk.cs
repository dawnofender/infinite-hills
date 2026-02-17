
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class polardetaildisk : UdonSharpBehaviour {
    VRCPlayerApi localPlayer;

    void Start() {
        localPlayer = Networking.LocalPlayer;
    }
    
    // Vector3 newPosition;
    // void PostLateUpdate() {
    //     newPosition = localPlayer.GetPosition();
    //     newPosition.y = 0;
    //     transform.position = newPosition;
    // }
}
