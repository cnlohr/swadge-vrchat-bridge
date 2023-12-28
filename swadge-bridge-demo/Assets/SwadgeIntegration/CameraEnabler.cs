
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class CameraEnabler : UdonSharpBehaviour
{
	public Camera toEnable;
    void Start()
    {
        toEnable.enabled = true;
    }
}
